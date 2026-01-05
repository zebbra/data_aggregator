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

    # work through the stream of records and prepare chunks of 1000 records for validation
    query = build_query(validation_request, tenant)

    query
    |> stream_query()
    |> Stream.chunk_every(1000)
    |> Stream.map(fn records ->
      records
      |> Enum.map(
        &process_validation_data(
          &1,
          validation_file,
          validation_request.inserted_at
        )
      )
      |> Counter.count_each(total_counter)
      |> Enum.filter(fn {maybe_changes, _record} ->
        maybe_changes == :changed
      end)
      |> Enum.map(fn {_, record} -> record end)
    end)
    |> Stream.flat_map(& &1)
    |> Counter.count_each(sent_counter)
    |> update_validation_status(:requested, ctx)

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
      case InfoSpecies.notify(validation_request, query, row_count) do
        {:ok, validation_request} ->
          {:ok, validation_request}

        {:error, error} ->
          Logger.error("Error while notifying about validation: #{inspect(error)}")

          query
          |> stream_query()
          |> update_validation_status(
            :unknown,
            ctx
          )

          {:error, error}
      end
    else
      {:ok, validation_request}
    end
  rescue
    e ->
      Logger.error("Error sending validation request: #{inspect(e)}")

      validation_request = input.arguments.validation_request

      validation_request
      |> build_query(tenant)
      |> stream_query()
      |> update_validation_status(:unknown, ctx)

      {:error, e}
  end

  defp build_query(validation_request, tenant) do
    Record
    |> Ash.Query.new()
    |> Ash.Query.filter_input(validation_request.records_query)
    |> Ash.Query.set_tenant(tenant)
    |> Ash.Query.load([:encoded_record, :collection, :validation_request_record])
  end

  @spec stream_query(Ash.Query.t()) :: Enum.t()
  defp stream_query(query), do: Ash.stream!(query, stream_with: :keyset, batch_size: 1000, load: :encoded_record)

  @spec update_validation_status(Enum.t(), atom(), Context.t()) :: Enum.t()
  defp update_validation_status(stream, status, %{actor: actor, tenant: tenant}) do
    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    Ash.bulk_update(stream, :update_validation_status, %{status: status},
      actor: actor,
      authorize?: false,
      domain: Records,
      resource: Record,
      tenant: tenant,
      max_concurrency: max_concurrency,
      batch_size: batch_size
    )

    stream
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

  @spec process_validation_data(Record.t(), ValidationFile.t(), DateTime.t()) ::
          {:not_changed, Record.t()} | {:changed, Record.t()}
  defp process_validation_data(record, validation_file, date_time) do
    case maybe_changed_data(record, validation_file) do
      {:not_changed, _data} ->
        {:not_changed, record}

      {:changed, data} ->
        upsert_validation_request_record!(record, data)

        data = format_data_for_validation(data, date_time)

        FlatFileUtils.store_on_disk!([data], validation_file.file, false)

        {:changed, record}
    end
  end

  # returns {:not_changed, previous_data} if there was no changes and returns {:changed, current_data} if there were
  # changes in the record data since the last validation
  @spec maybe_changed_data(Record.t(), ValidationFile.t()) ::
          {:not_changed, map()} | {:changed, map()}
  defp maybe_changed_data(record, validation_file) do
    previous_data = previous_data(record)
    current_data = current_data(record, validation_file)

    if previous_data == current_data do
      Logger.info("Validation Request: No changes detected. No data will be sent for validation.")

      {:not_changed, previous_data}
    else
      Logger.info("Validation Request: Changes detected, new data will be sent for validation.")

      {:changed, current_data}
    end
  end

  # returns the data which was previously sent for validation
  @spec previous_data(Record.t()) :: map() | nil
  defp previous_data(record) do
    case record.validation_request_record do
      nil -> nil
      previous_data -> previous_data.data
    end
  end

  # returns the attributes, values and headers for further processing towards a validation request
  @spec current_data(Record.t(), ValidationFile.t()) :: map()
  defp current_data(record, validation_file) do
    collection_attributes = Keyword.keys(validation_file.collection_attributes_and_headers)
    record_attributes = Keyword.keys(validation_file.record_attributes_and_headers)
    encoded_attributes = Keyword.keys(validation_file.encoded_attributes_and_headers)

    reduced_collection_data = Map.take(record.collection, collection_attributes)
    reduced_record_data = Map.take(record, record_attributes)
    reduced_encoded_data = Map.take(record.encoded_record, encoded_attributes)

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

  @spec upsert_validation_request_record!(Record.t(), map()) :: ValidationRequestRecord.t()
  defp upsert_validation_request_record!(record, data) do
    case record.validation_request_record do
      nil ->
        ValidationRequestRecord.create!(
          %{
            data: data,
            collection: record.collection,
            record: record
          },
          tenant: record.collection
        )

      vrr ->
        ValidationRequestRecord.update!(vrr, %{data: data}, tenant: record.collection)
    end
  end
end
