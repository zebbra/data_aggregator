defmodule DataAggregator.Records.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Publication.CoreFile
  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.PublicationStatus
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
      "collecting data for publication",
      publication
    )

    path = DwcaFile.create_directory!("publication_#{channel}")

    CoreFile.create(query, path)
    # AnyExtensionFile.create(query, path)

    attachment = path |> create_zip_file!() |> store_on_s3!()

    set_publication_status(
      query,
      channel,
      :in_publication,
      "data collected successful, publication process started",
      publication
    )

    Publication.update_attachment(publication, attachment)
    # rescue
    #   e ->
    #     Logger.error("Error publishing records on the fast track: #{inspect(e)}")

    #     set_publication_status(
    #       input.arguments.publication.records_query,
    #       input.arguments.publication.channel,
    #       :publication_failed,
    #       inspect(e),
    #       input.arguments.publication
    #     )

    #     {:error, e}
  end

  @spec create_zip_file!(String.t()) :: String.t()
  defp create_zip_file!(path) do
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
          String.t(),
          Publication.t()
        ) :: :ok
  defp set_publication_status(query, channel, status, message, publication) do
    publication_status =
      Map.from_struct(%PublicationStatus{channel: channel, status: status, message: message})

    query
    |> Records.stream!()
    |> Stream.map(&update_record!(&1, publication_status, publication))
    |> Stream.run()
  end

  @spec update_record!(Record.t(), map(), Publication.t()) :: :ok
  defp update_record!(record, status, publication) do
    Publication.add_publication_progress(publication, 1)

    Record.update_publication_status(record, status)
    :ok
  end
end
