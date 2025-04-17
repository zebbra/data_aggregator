defmodule DataAggregator.Records.Collection.Actions.Validate do
  @moduledoc """
  Custom action to send a validation request to the infospecies center for a selection of records.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Counter
  alias DataAggregator.DarwinCore.Publication.CoreFile
  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.DarwinCore.Publication.EmlFile
  alias DataAggregator.DarwinCore.Publication.MaterialSampleFile
  alias DataAggregator.DarwinCore.Publication.MetaFile
  alias DataAggregator.DarwinCore.Publication.PreservationFile
  alias DataAggregator.DarwinCore.Publication.ReleveFile
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.InfoSpecies
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    validation = input.arguments.publication

    # these are the new records that will be validated
    query =
      Record
      |> AshPagify.query_for_filters_map(validation.records_query)
      |> Ash.Query.set_tenant(tenant)

    collection = validation.collection

    path = FlatFileUtils.create_directory!("publication_#{validation.channel}")
    EmlFile.create(collection, validation, path)
    MetaFile.create(collection, path)

    {:ok, counter} = Counter.start(&Publication.add_publication_progress(validation, &1))

    file_metas = [
      CoreFile.open_file!(path),
      MaterialSampleFile.open_file!(path),
      PreservationFile.open_file!(path),
      ReleveFile.open_file!(path)
    ]

    Enum.each(file_metas, &DwcaFile.write_headers(&1))

    query
    |> stream_query()
    |> set_publication_status(:validating, ctx)
    |> Stream.chunk_every(1000)
    |> Stream.flat_map(fn records ->
      file_metas
      |> Task.async_stream(
        &DwcaFile.write_file!(records, &1, collection),
        timeout: to_timeout(second: 30)
      )
      |> Stream.run()

      records
    end)
    |> Counter.count_each(counter)
    |> set_publication_status(:in_validation, ctx)

    Enum.each(file_metas, &FlatFileUtils.close_file(&1.file_descriptor))

    Counter.stop(counter)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()
    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    validation =
      validation
      |> Publication.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    case validate(validation, query, ctx) do
      {:ok, validation} ->
        {:ok, validation}

      {:error, error} ->
        Logger.error("Error validating records on the #{validation.channel} channel: #{inspect(error)}")

        query
        |> stream_query()
        |> set_publication_status(
          :validation_failed,
          ctx
        )

        {:error, error}
    end
  rescue
    e ->
      validation = input.arguments.publication

      query =
        Record
        |> AshPagify.query_for_filters_map(validation.records_query)
        |> Ash.Query.set_tenant(tenant)

      Logger.error("Error validating records on the #{validation.channel} channel: #{inspect(e)}")

      query
      |> stream_query()
      |> set_publication_status(
        :validation_failed,
        ctx
      )

      {:error, e}
  end

  defp stream_query(query), do: Ash.stream!(query, stream_with: :keyset, batch_size: 1000, load: :encoded_record)

  defp set_publication_status(stream, status, %{actor: actor, tenant: tenant}) do
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

  defp validate(%Publication{channel: :validation} = validation, query, _ctx) do
    case InfoSpecies.notify(validation, query) do
      {:ok, validation} ->
        {:ok, validation}

      {:error, error} ->
        Logger.warning("Error while informing infospecies about new available records for review: #{inspect(error)}")

        {:error, error}
    end
  end
end
