defmodule DataAggregator.Records.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Publication.ChronometricAgeFile
  alias DataAggregator.DarwinCore.Publication.CoreFile
  alias DataAggregator.DarwinCore.Publication.DistributionFile
  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.DarwinCore.Publication.MaterialSampleFile
  alias DataAggregator.DarwinCore.Publication.MultimediaFile
  alias DataAggregator.DarwinCore.Publication.PermitFile
  alias DataAggregator.DarwinCore.Publication.PreservationFile
  alias DataAggregator.DarwinCore.Publication.ReferencesFile
  alias DataAggregator.DarwinCore.Publication.ReleveFile
  alias DataAggregator.DarwinCore.Publication.ResourceRelationshipFile
  alias DataAggregator.DarwinCore.Publication.SpeciesProfileFile
  alias DataAggregator.DarwinCore.Publication.VernacularNamesFile
  alias DataAggregator.Files.Attachment
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

    path = DwcaFile.create_directory!("publication_#{channel}")

    CoreFile.create(query, path)
    ChronometricAgeFile.create(query, path)
    DistributionFile.create(query, path)
    MaterialSampleFile.create(query, path)
    PermitFile.create(query, path)
    PreservationFile.create(query, path)
    ReferencesFile.create(query, path)
    ReleveFile.create(query, path)
    ResourceRelationshipFile.create(query, path)
    SpeciesProfileFile.create(query, path)
    VernacularNamesFile.create(query, path)
    MultimediaFile.create(query, path)

    attachment = path |> create_zip!() |> store_on_s3!()

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

  @spec create_zip!(String.t()) :: String.t()
  defp create_zip!(path) do
    zip_path = ~c"#{path}/#{Ecto.UUID.generate()}.zip"
    files = get_files(path)
    directory_path = ~c"#{path}/"

    case :zip.create(zip_path, files, [{:cwd, directory_path}]) do
      {:ok, _} ->
        to_string(zip_path)

      {:error, reason} ->
        raise "Error creating zip file: #{inspect(reason)}"
    end
  end

  @spec get_files(String.t()) :: list(charlist())
  defp get_files(path) do
    path
    |> File.ls!()
    |> Enum.map(&String.to_charlist/1)
  end

  @spec store_on_s3!(String.t()) :: Attachment.t()
  defp store_on_s3!(path) do
    Attachment.import_from_path!(path)
  end

  @spec set_publication_status(
          Ash.Query.t(),
          atom(),
          atom(),
          Publication.t()
        ) :: :ok
  defp set_publication_status(query, channel, status, publication) do
    query
    |> Records.stream!()
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
