defmodule DataAggregator.Records.Collection.Actions.Validate do
  @moduledoc """
  Custom action to send a validation request to the infospecies center for a selection of records.
  """

  use Ash.Resource.Actions.Implementation

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Counter
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Validation.ValidationFile
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.InfoSpecies
  alias DataAggregator.Records.ValidationRequestRecord
  alias Explorer.DataFrame

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    validation_request = Ash.load!(input.arguments.validation_request, [:collection])

    {:ok, total_counter} =
      Counter.start(&ValidationRequest.add_validation_request_progress(validation_request, &1))

    {:ok, sent_counter} =
      Counter.start(&ValidationRequest.add_sent_for_validation_progress(validation_request, &1))

    path = FlatFileUtils.create_directory!("validation_request")

    %{file: file} = validation_file = ValidationFile.open_file!(path)

    header_labels = compose_headers(validation_file)

    FlatFileUtils.store_on_disk!(
      [header_labels],
      validation_file.file,
      false
    )

    # Stream encoded_records (where the filter lives) instead of records so every
    # batch is bounded by LIMIT 1000 on the driving table. Record + VRR are
    # loaded via nested belongs_to / has_one so they come back in bounded PK
    # lookups per batch.
    collection = validation_request.collection

    validation_request
    |> build_encoded_stream_query(tenant)
    |> stream_query()
    |> Stream.chunk_every(1000)
    |> Enum.each(fn encoded_records ->
      results =
        encoded_records
        |> Enum.map(
          &process_validation_data(
            &1,
            validation_file,
            validation_request.inserted_at,
            collection
          )
        )
        |> Counter.count_each(total_counter)

      changed_with_data =
        Enum.filter(results, fn {status, _encoded_record, _data} -> status == :changed end)

      if changed_with_data != [] do
        bulk_upsert_validation_request_records!(changed_with_data, validation_request, tenant)
      end

      Counter.increment(sent_counter, length(changed_with_data))
    end)

    FlatFileUtils.close_file(file)
    Counter.stop(total_counter)
    Counter.stop(sent_counter)

    attachment =
      path
      |> FlatFileUtils.create_zip!()
      |> FlatFileUtils.store_on_s3!(validation_request.collection)

    row_count =
      validation_file.path
      |> DataFrame.from_csv!(infer_schema_length: 0)
      |> DataFrame.n_rows()

    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    validation_request = ValidationRequest.update_attachment!(validation_request, attachment)

    # only notify center if there are more than 0 entries to validate
    if row_count > 0 do
      case InfoSpecies.notify(validation_request, row_count) do
        {:ok, validation_request} ->
          # Use VRR table to find records changed in this run, instead of
          # accumulating all IDs in memory during the stream.
          bulk_update_changed_records(validation_request, tenant, ctx)
          {:ok, validation_request}

        {:error, error} ->
          # Nothing to revert — no record statuses were touched yet.
          Logger.error("Error while notifying about validation: #{inspect(error)}")
          {:error, error}
      end
    else
      {:ok, validation_request}
    end
  rescue
    e ->
      Logger.error("Error sending validation request: #{inspect(e)}")
      validation_request = input.arguments.validation_request
      rollback_changed_records(validation_request, tenant)
      {:error, e}
  end

  # Valid only while every records_query predicate lives under :encoded_record
  # (or :collection). Revisit if a record-only filter is ever added.
  defp build_encoded_stream_query(validation_request, tenant) do
    EncodedRecord
    |> Ash.Query.new()
    |> Ash.Query.filter_input(encoded_filter(validation_request))
    |> Ash.Query.set_tenant(tenant)
    |> Ash.Query.load(record: [:validation_request_record])
  end

  defp encoded_filter(validation_request) do
    validation_request.records_query[:encoded_record] ||
      validation_request.records_query["encoded_record"] ||
      %{}
  end

  @spec stream_query(Ash.Query.t()) :: Enum.t()
  defp stream_query(query),
    do: Ash.stream!(query, stream_with: :keyset, batch_size: 1000, load: [record: [:validation_request_record]])

  @spec bulk_update_changed_records(ValidationRequest.t(), term(), Context.t()) :: :ok
  defp bulk_update_changed_records(validation_request, tenant, %{actor: actor}) do
    changed_record_ids_query()
    |> Ash.Query.filter(validation_request_id == ^validation_request.id)
    |> Ash.Query.set_tenant(tenant)
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000)
    |> Stream.map(& &1.record_id)
    |> Stream.chunk_every(1000)
    |> Enum.each(fn ids ->
      Record
      |> Ash.Query.filter(id in ^ids)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.bulk_update!(:update_validation_status, %{status: :requested},
        actor: actor,
        authorize?: false,
        domain: Records,
        resource: Record,
        tenant: tenant,
        batch_size: 1000,
        return_errors?: true
      )

      Record
      |> Ash.Query.filter(id in ^ids)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.bulk_update!(:update_last_validation_started_at, %{},
        actor: actor,
        authorize?: false,
        domain: Records,
        resource: Record,
        tenant: tenant,
        batch_size: 1000,
        return_errors?: true
      )
    end)
  end

  # On failure, delete VRRs that were upserted during this run so the next
  # validation request correctly detects those records as changed again.
  # No need to reset validation statuses — they are only updated after notify succeeds.
  @spec rollback_changed_records(ValidationRequest.t(), term()) :: :ok
  defp rollback_changed_records(validation_request, tenant) do
    ValidationRequestRecord
    |> Ash.Query.filter(validation_request_id == ^validation_request.id)
    |> Ash.Query.set_tenant(tenant)
    |> Ash.bulk_destroy!(:destroy, %{},
      authorize?: false,
      domain: Records,
      tenant: tenant,
      batch_size: 500,
      return_errors?: true
    )

    :ok
  rescue
    e ->
      Logger.error("Error during rollback of validation request records: #{inspect(e)}")
      :ok
  end

  defp changed_record_ids_query do
    ValidationRequestRecord
    |> Ash.Query.new()
    |> Ash.Query.select([:record_id, :validation_request_id])
  end

  @spec compose_headers(ValidationFile.t()) :: list()
  defp compose_headers(validation_file) do
    collection_headers = get_sorted_headers(validation_file.collection_attributes_and_headers)
    record_headers = get_sorted_headers(validation_file.record_attributes_and_headers)
    encoded_headers = get_sorted_headers(validation_file.encoded_attributes_and_headers)

    collection_headers ++ record_headers ++ encoded_headers ++ ["dateOfValidation"]
  end

  @spec get_sorted_headers(Keyword.t()) :: list()
  defp get_sorted_headers(headers_and_attributes) do
    headers_and_attributes
    |> Keyword.values()
    |> Enum.sort(&(&1 <= &2))
  end

  @spec process_validation_data(
          EncodedRecord.t(),
          ValidationFile.t(),
          DateTime.t(),
          Collection.t()
        ) ::
          {:not_changed, EncodedRecord.t(), nil}
          | {:changed, EncodedRecord.t(), map()}
          | {:missing_record, EncodedRecord.t(), nil}
  defp process_validation_data(%{record: nil} = encoded_record, _validation_file, _date_time, _collection) do
    # we skip validation for encoded records without a record
    # they are likeley the result of an error, should not happen
    {:missing_record, encoded_record, nil}
  end

  defp process_validation_data(encoded_record, validation_file, date_time, collection) do
    case maybe_changed_data(encoded_record, validation_file, collection) do
      {:not_changed, _data} ->
        {:not_changed, encoded_record, nil}

      {:changed, data} ->
        formatted = format_data_for_validation(data, date_time)
        FlatFileUtils.store_on_disk!([formatted], validation_file.file, false)

        {:changed, encoded_record, data}
    end
  end

  # returns {:not_changed, previous_data} if there was no changes and returns {:changed, current_data} if there were
  # changes in the record data since the last validation
  @spec maybe_changed_data(EncodedRecord.t(), ValidationFile.t(), Collection.t()) ::
          {:not_changed, map()} | {:changed, map()}
  defp maybe_changed_data(encoded_record, validation_file, collection) do
    previous_data = previous_data(encoded_record)
    current_data = current_data(encoded_record, validation_file, collection)

    if previous_data == current_data do
      Logger.debug("Validation Request: No changes detected. No data will be sent for validation.")

      {:not_changed, previous_data}
    else
      Logger.debug("Validation Request: Changes detected, new data will be sent for validation.")

      {:changed, current_data}
    end
  end

  # returns the data which was previously sent for validation
  @spec previous_data(EncodedRecord.t()) :: map() | nil
  defp previous_data(%{record: %{validation_request_record: %{data: data}}}), do: data
  defp previous_data(_), do: nil

  # returns the attributes, values and headers for further processing towards a validation request
  @spec current_data(EncodedRecord.t(), ValidationFile.t(), Collection.t()) :: map()
  defp current_data(encoded_record, validation_file, collection) do
    collection_attributes = Keyword.keys(validation_file.collection_attributes_and_headers)
    record_attributes = Keyword.keys(validation_file.record_attributes_and_headers)
    encoded_attributes = Keyword.keys(validation_file.encoded_attributes_and_headers)

    reduced_collection_data = Map.take(collection, collection_attributes)
    reduced_record_data = Map.take(encoded_record.record, record_attributes)
    reduced_encoded_data = Map.take(encoded_record, encoded_attributes)

    collection_data =
      reduced_collection_data
      |> Enum.map(fn {attr, value} ->
        value_with_header_and_attribute(
          value,
          validation_file.collection_attributes_and_headers[attr],
          attr
        )
      end)
      |> sort_data_by_header()

    record_data =
      reduced_record_data
      |> Enum.map(fn {attr, value} ->
        value = maybe_transform_value({attr, value})

        value_with_header_and_attribute(
          value,
          validation_file.record_attributes_and_headers[attr],
          attr
        )
      end)
      |> sort_data_by_header()

    encoded_data =
      reduced_encoded_data
      |> Enum.map(fn {attr, value} ->
        value = maybe_transform_value({attr, value})

        value_with_header_and_attribute(
          value,
          validation_file.encoded_attributes_and_headers[attr],
          attr
        )
      end)
      |> sort_data_by_header()

    %{
      "collection_data" => collection_data,
      "record_data" => record_data,
      "encoded_data" => encoded_data
    }
  end

  @spec maybe_transform_value({atom(), any()}) :: any()
  defp maybe_transform_value({attr, value}) do
    [{attr, value}]
    |> Map.new()
    |> FlatFileUtils.maybe_transform_data(attr, Schema.dwc_transformers())
  end

  @spec sort_data_by_header(list(map())) :: list(map())
  defp sort_data_by_header(data) do
    Enum.sort(data, &(&1["header"] <= &2["header"]))
  end

  @spec value_with_header_and_attribute(any(), String.t(), atom() | String.t()) :: map()
  defp value_with_header_and_attribute(value, header, attribute) do
    %{
      "attr" => to_string(attribute),
      "value" => value,
      "header" => header
    }
  end

  @spec format_data_for_validation(map(), DateTime.t()) :: list()
  defp format_data_for_validation(
         %{"collection_data" => collection_data, "record_data" => record_data, "encoded_data" => encoded_data},
         date_time
       ) do
    data =
      [collection_data, record_data, encoded_data]
      |> List.flatten()
      |> Enum.map(& &1["value"])

    data ++ [date_time]
  end

  @spec bulk_upsert_validation_request_records!(list(), ValidationRequest.t(), term()) :: :ok
  defp bulk_upsert_validation_request_records!(changed_with_data, validation_request, tenant) do
    inputs =
      Enum.map(changed_with_data, fn {_status, encoded_record, data} ->
        %{
          data: data,
          record_id: encoded_record.record_id,
          validation_request_id: validation_request.id
        }
      end)

    # VRR has few columns (~6), so batches of 500 stay well within PG's 65535 param limit
    Ash.bulk_create!(inputs, ValidationRequestRecord, :bulk_upsert,
      batch_size: 500,
      tenant: tenant,
      authorize?: false,
      domain: Records,
      return_errors?: true
    )

    :ok
  end
end
