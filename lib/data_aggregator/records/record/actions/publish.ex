defmodule DataAggregator.Records.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Publication.CoreFile
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
  def run(input, _opts, _context) do
    publication = input.arguments.publication

    query = get_ash_query(publication)

    set_publication_status(
      query,
      :publishing,
      publication
    )

    path = FlatFileUtils.create_directory!("publication_#{publication.channel}")

    CoreFile.create(query, path)

    EmlFile.create(publication.collection, path)

    MaterialSampleFile.create(query, path)
    PreservationFile.create(query, path)
    ReleveFile.create(query, path)

    MetaFile.create(publication.collection, path)

    # TODO: implement the following files, they contain of attributes from json fields,
    # and therefore need to be implemented in a different way

    # ChronometricAgeFile.create(query, path)
    # DistributionFile.create(query, path)
    # PermitFile.create(query, path)
    # ReferencesFile.create(query, path)
    # ResourceRelationshipFile.create(query, path)
    # SpeciesProfileFile.create(query, path)
    # VernacularNamesFile.create(query, path)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()

    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    set_publication_status(
      query,
      :in_publication,
      publication
    )

    publication =
      publication
      |> Publication.update_attachment(attachment)
      |> Records.load!([:collection, :attachment])

    register(publication, query)
  rescue
    e ->
      publication = input.arguments.publication
      query = get_ash_query(publication)

      Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(e)}")

      set_publication_status(
        query,
        :publication_failed,
        publication
      )

      {:error, e}
  end

  def get_ash_query(publication) do
    Ash.Query.filter_input(Record, publication.records_query)
  end

  @spec queue_records_for_verification(Ash.Query.t()) :: :ok
  defp queue_records_for_verification(query) do
    query
    |> Records.stream!(page: false)
    |> Stream.map(&Record.enqueue_fast_track_checker/1)
    |> Stream.run()
  end

  @spec set_publication_status(
          Ash.Query.t(),
          atom(),
          Publication.t()
        ) :: :ok
  defp set_publication_status(query, status, publication) do
    query
    |> Records.stream!(page: false)
    |> Stream.map(&update_record!(&1, status, publication))
    |> Stream.run()
  end

  @spec update_record!(Record.t(), atom(), Publication.t()) :: :ok
  defp update_record!(record, status, publication) do
    if Records.execute_async?() do
      Task.start(fn -> Publication.add_publication_progress!(publication, 1) end)
    else
      Publication.add_publication_progress!(publication, 1)
    end

    update_status!(publication.channel, status, record)
  end

  defp update_status!(:fast_track, status, record), do: Record.update_fast_track_status!(record, status)

  defp update_status!(:approval, status, record), do: Record.update_approval_status!(record, translate_status(status))

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
end
