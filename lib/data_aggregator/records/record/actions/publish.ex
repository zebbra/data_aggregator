defmodule DataAggregator.Records.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Publication.CoreFile
  alias DataAggregator.DarwinCore.Publication.MaterialSampleFile
  alias DataAggregator.DarwinCore.Publication.MultimediaFile
  alias DataAggregator.DarwinCore.Publication.PreservationFile
  alias DataAggregator.DarwinCore.Publication.ReleveFile
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, _context) do
    publication = input.arguments.publication
    query = publication.records_query
    channel = publication.channel

    set_publication_status(
      query,
      channel,
      :publishing,
      publication
    )

    path = FlatFileUtils.create_directory!("publication_#{channel}")

    CoreFile.create(query, path)
    MaterialSampleFile.create(query, path)
    PreservationFile.create(query, path)
    ReleveFile.create(query, path)
    MultimediaFile.create(query, path)

    # TODO: implement the following files, they contain of
    #  attributes from json data, so a dfiferent approach is needed

    # ChronometricAgeFile.create(query, path)
    # DistributionFile.create(query, path)
    # PermitFile.create(query, path)
    # ReferencesFile.create(query, path)
    # ResourceRelationshipFile.create(query, path)
    # SpeciesProfileFile.create(query, path)
    # VernacularNamesFile.create(query, path)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()

    set_publication_status(
      query,
      channel,
      :in_publication,
      publication
    )

    Publication.update_attachment(publication, attachment)
  rescue
    e ->
      publication = input.arguments.publication
      query = publication.records_query
      channel = publication.channel

      Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(e)}")

      set_publication_status(
        query,
        channel,
        :publication_failed,
        publication
      )

      {:error, e}
  end

  @spec set_publication_status(
          Ash.Query.t(),
          atom(),
          atom(),
          Publication.t()
        ) :: :ok
  defp set_publication_status(query, channel, status, publication) do
    query
    |> Records.stream!(page: false)
    |> Stream.map(&update_record!(&1, channel, status, publication))
    |> Stream.run()
  end

  @spec update_record!(Record.t(), atom(), atom(), Publication.t()) :: :ok
  defp update_record!(record, channel, status, publication) do
    Publication.add_publication_progress(publication, 1)

    update_status(channel, status, record)
    :ok
  end

  defp update_status(:fast_track, status, record), do: Record.update_fast_track_status(record, status)

  defp update_status(:approval, status, record), do: Record.update_approval_status(record, status)
end
