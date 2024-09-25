defmodule DataAggregator.Records.ImageUpload.Changes.ExtractImages do
  @moduledoc """
  Changeset hook to extract images from the image upload attachment and upload them to the storage.
  """
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &extract_images(&1, ctx), append?: true)
  end

  defp extract_images(%Changeset{data: image_upload} = changeset, _ctx) do
    Logger.info("Extracting images from attachment for #{inspect(image_upload.id)} ...")

    with %ImageUpload{} = image_upload <-
           Ash.load!(image_upload, [attachment: :cached_file], lazy?: true),
         {:cached_file, cached_file} when is_binary(cached_file) <-
           {:cached_file, image_upload.attachment.cached_file},
         {:temp_path, temp_path} <-
           {:temp_path, FlatFileUtils.create_directory!("image_upload_#{image_upload.id}")},
         {:unzip, {:ok, _}} <- {:unzip, unzip_cached_file(cached_file, temp_path)},
         {:attachments, attachments} <-
           {:attachments, temp_path |> File.ls!() |> Enum.map(&%{path: temp_path <> "/" <> &1, filename: &1})} do
      Changeset.manage_relationship(changeset, :image_attachments, attachments, type: :create)
    else
      {:cached_file, _} ->
        add_error(changeset, "Could not load cached file")

      {:unzip, {:error, error}} ->
        add_error(changeset, "Could not unzip attachment: #{error}")

      error ->
        add_error(changeset, "Error during file extraction: #{error}")
    end
  end

  defp unzip_cached_file(cached_file, temp_path) do
    Logger.info("Unzipping attachment to #{temp_path} ...")

    cached_file
    |> to_charlist()
    |> :zip.unzip([{:cwd, to_charlist(temp_path)}])
  end

  defp add_error(changeset, error) do
    Logger.warning("Error extracting images: #{inspect(error)}")
    Changeset.add_error(changeset, error)
  end
end
