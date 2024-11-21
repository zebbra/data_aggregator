defmodule DataAggregator.Records.Collection.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias Ash.Resource.Actions.Implementation.Context
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
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.InfoSpecies
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    publication = input.arguments.publication

    query =
      Record
      |> AshPagify.query_for_filters_map(publication.records_query)
      |> Ash.Query.set_tenant(tenant)

    path = FlatFileUtils.create_directory!("publication_#{publication.channel}")
    EmlFile.create(publication.collection, path)
    MetaFile.create(publication.collection, path)

    {:ok, counter} = Counter.start(&Publication.add_publication_progress(publication, &1))

    file_metas = [
      CoreFile.open_file!(path),
      MaterialSampleFile.open_file!(path),
      PreservationFile.open_file!(path),
      ReleveFile.open_file!(path)
    ]

    Enum.each(file_metas, &DwcaFile.write_headers(&1))

    query
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000, load: :encoded_record)
    |> set_publication_status(:publishing, publication, ctx)
    |> Stream.chunk_every(1000)
    |> Stream.flat_map(fn records ->
      file_metas
      |> Task.async_stream(&DwcaFile.write_file!(records, &1),
        timeout: :timer.seconds(30)
      )
      |> Stream.run()

      records
    end)
    |> Counter.count_each(counter)
    |> set_publication_status(:in_publication, publication, ctx)

    Enum.each(file_metas, &FlatFileUtils.close_file(&1.file_descriptor))

    Counter.stop(counter)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()
    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    publication =
      publication
      |> Publication.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    case register(publication, query) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(error)}")

        set_publication_status(
          Ash.stream!(query, stream_with: :keyset, batch_size: 1000),
          :publication_failed,
          publication,
          ctx
        )

        {:error, error}
    end
  rescue
    e ->
      publication = input.arguments.publication

      query =
        Record
        |> AshPagify.query_for_filters_map(publication.records_query)
        |> Ash.Query.set_tenant(tenant)

      Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(e)}")

      set_publication_status(
        Ash.stream!(query, stream_with: :keyset, batch_size: 1000),
        :publication_failed,
        publication,
        ctx
      )

      {:error, e}
  end

  @spec set_publication_status(Enumerable.t(), atom(), Publication.t(), Context.t()) ::
          Enumerable.t()
  defp set_publication_status(stream, status, publication, %{actor: actor, tenant: tenant}) do
    action =
      if publication.channel == :fast_track,
        do: :update_fast_track_status,
        else: :update_approval_status

    status = if action == :update_approval_status, do: translate_status(status), else: status

    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    Ash.bulk_update(stream, action, %{status: status},
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

  defp translate_status(:publishing), do: :approving
  defp translate_status(:in_publication), do: :in_approval
  defp translate_status(:publication_failed), do: :approval_failed

  defp register(%Publication{channel: :approval} = publication, query) do
    case InfoSpecies.notify(publication, query) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.warning("Error while informing infospecies about new available records for review: #{inspect(error)}")

        {:error, error}
    end
  end

  defp register(%Publication{channel: :fast_track} = publication, query) do
    with {:ok, _collection} <-
           Collection.register_at_gbif(publication.collection, publication.attachment.url),
         :ok <- queue_records_for_verification(query) do
      {:ok, publication}
    end
  end

  @spec queue_records_for_verification(Ash.Query.t()) :: :ok
  defp queue_records_for_verification(query) do
    query
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000)
    |> Enum.each(&Record.enqueue_fast_track_checker/1)
  end
end
