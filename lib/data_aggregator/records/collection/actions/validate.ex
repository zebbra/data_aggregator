defmodule DataAggregator.Records.Collection.Actions.Validate do
  @moduledoc """
  Custom action to send a validation request to the infospecies center for a selection of records.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Counter
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Validation.ValidationFile
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.InfoSpecies
  alias DataAggregator.Records.ValidationRequestRecord

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    validation_request = input.arguments.validation_request

    # these are the new records that will be validated
    query =
      Record
      |> Ash.Query.new()
      |> Ash.Query.filter_input(validation_request.records_query)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.Query.load([:encoded_record, :collection, :validation_request_record])

    path = FlatFileUtils.create_directory!("validation_request")

    {:ok, counter} =
      Counter.start(&ValidationRequest.add_validation_request_progress(validation_request, &1))

    %{
      file: file,
      headers: headers,
      record_attributes: record_attributes,
      collection_attributes: collection_attributes
    } = ValidationFile.open_file!(path)

    FlatFileUtils.store_on_disk!(headers, file)

    query
    |> stream_query()
    |> Stream.chunk_every(1000)
    |> Stream.map(fn records ->
      Enum.each(records, fn record ->
        process_validation_data(record, record_attributes, collection_attributes, file, headers)

        :ok
      end)

      records
    end)
    |> Counter.count_each(counter)
    |> update_validation_status(:requested, ctx)

    FlatFileUtils.close_file(file)
    Counter.stop(counter)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()

    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    validation_request =
      validation_request
      |> ValidationRequest.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    case validate(validation_request, query, ctx) do
      {:ok, validation_request} ->
        {:ok, validation_request}

      {:error, error} ->
        Logger.error("Error sending validation request: #{inspect(error)}")

        query
        |> stream_query()
        |> update_validation_status(
          :validation_failed,
          ctx
        )

        {:error, error}
    end
  rescue
    e ->
      validation_request = input.arguments.validation_request

      query =
        Record
        |> AshPagify.query_for_filters_map(validation_request.records_query)
        |> Ash.Query.set_tenant(tenant)

      Logger.error("Error sending validation request: #{inspect(e)}")

      query
      |> stream_query()
      |> update_validation_status(
        :validation_failed,
        ctx
      )

      {:error, e}
  end

  defp stream_query(query), do: Ash.stream!(query, stream_with: :keyset, batch_size: 1000, load: :encoded_record)

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

  defp process_validation_data(record, record_attributes, collection_attributes, file, headers) do
    case data(record, record_attributes, collection_attributes) do
      {:no_changes, _data} ->
        :ok

      {:changes, data} ->
        upsert_validation_request_record(record, data)

        FlatFileUtils.store_on_disk!(data, file, headers)

        :ok
    end
  end

  defp validate(%ValidationRequest{} = validation_request, query, _ctx) do
    case InfoSpecies.notify(validation_request, query) do
      {:ok, validation_request} ->
        {:ok, validation_request}

      {:error, error} ->
        Logger.warning("Error while informing infospecies about new available records for review: #{inspect(error)}")

        {:error, error}
    end
  end

  # returns {:no_changes, previous_data} if there was no changes and returns {:ok, current_data} if there were
  # changes in the record data since the last validation
  defp data(record, record_attributes, collection_attributes) do
    previous_data = previous_data(record)

    current_data = current_data(record, record_attributes, collection_attributes)

    if previous_data == current_data do
      {:no_changes, previous_data}
    else
      {:changes, current_data}
    end
  end

  # returns the data which was previously sent for validation
  defp previous_data(record) do
    case record.validation_request_record do
      nil -> nil
      previous_data -> previous_data.data |> Map.to_list() |> Enum.sort()
    end
  end

  # returns the data which would be sent for validation now
  defp current_data(record, record_attributes, collection_attributes) do
    record_data = record |> Map.take(record_attributes) |> Map.to_list() |> Enum.sort()

    collection_data =
      record.collection |> Map.take(collection_attributes) |> Map.to_list() |> Enum.sort()

    encoded_data =
      record.encoded_record
      |> Map.take(record_attributes)
      |> Map.to_list()
      |> Enum.sort()
      |> Enum.map(fn {key, value} -> {"encoded.#{key}", value} end)

    collection_data ++ record_data ++ encoded_data
  end

  defp upsert_validation_request_record(record, data) do
    case record.validation_request_record do
      nil ->
        ValidationRequestRecord.create!(%{
          data: data,
          collection: record.collection,
          record: record
        })

      vrr ->
        ValidationRequestRecord.update!(vrr, %{data: data})
    end
  end
end
