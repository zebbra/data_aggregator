defmodule DataAggregator.Records.ImageUpload.Changes.ExtractImages do
  @moduledoc """
  Changeset hook to extract images from the image upload attachment and upload them to the storage.
  """
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.ImageUpload

  require Logger

  @accepted_image_extensions ~w(.jpg .jpeg .png .bmp .tiff .svg .webp)
  @max_image_size 5_000_000

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
         {:validate, invalid_file_infos} <- {:validate, validate_files(temp_path)},
         {:add_invalid_file_info, changeset} <-
           {:add_invalid_file_info, Changeset.change_attribute(changeset, :invalid_file_infos, invalid_file_infos)},
         {:attachments, attachments} <-
           {:attachments, create_attachments(temp_path)} do
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

  defp validate_files(temp_path) do
    Logger.info("Validating extracted files ...")

    temp_path
    |> File.ls!()
    |> Enum.map(&validate_file(&1, temp_path))
    |> Enum.filter(&is_map/1)
  end

  defp validate_file(file, temp_path) do
    with {:ok, stats} <- File.stat(temp_path <> "/" <> file),
         ext = get_extenstion(file),
         :ok <- validate_extension(ext),
         :ok <- validate_size(stats.size) do
      {:ok, file}
    else
      {:error, :file_size, size} ->
        Logger.info("File size (#{size}) exceeds maximum allowed size of #{@max_image_size}")
        Logger.info("Deleting file: #{temp_path}/#{file}")
        File.rm!(temp_path <> "/" <> file)
        %{filename: file, reason: :file_size}

      {:error, :file_extension, ext} ->
        Logger.info("Invalid file extension: #{ext}")
        Logger.info("Deleting file: #{temp_path}/#{file}")
        File.rm!(temp_path <> "/" <> file)
        %{filename: file, reason: :file_extension}

      {:error, error} ->
        Logger.warning("Error validating file: #{inspect(error)}")
    end
  end

  defp validate_size(size) do
    if size <= @max_image_size do
      :ok
    else
      {:error, :file_size, size}
    end
  end

  defp validate_extension(ext) do
    if ext in @accepted_image_extensions do
      :ok
    else
      {:error, :file_extension, ext}
    end
  end

  defp get_extenstion(file) do
    file |> Path.extname() |> String.downcase()
  end

  defp create_attachments(temp_path) do
    temp_path
    |> File.ls!()
    |> Enum.map(&%{path: temp_path <> "/" <> &1, filename: &1})
  end

  defp add_error(changeset, error) do
    Logger.warning("Error extracting images: #{inspect(error)}")
    Changeset.add_error(changeset, error)
  end
end
