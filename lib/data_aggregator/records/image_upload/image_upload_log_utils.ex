defmodule DataAggregator.Utils.ImageUploadLogUtils do
  @moduledoc """
  This module contains helper functions for generating and downloading image upload logs.
  """
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.ImageUpload

  @file_headers [
    filename: "Filename",
    status: "Status",
    message: "Message",
    matched_attribute: "Matched Attribute"
  ]

  @doc """
  Generates the log content for the given image upload.

  ## Parameters
  - image_upload: The image upload record for which the log content is generated.

  ## Returns
  - The path to the generated log file.
  """
  @spec generate_log_content(ImageUpload.t()) :: String.t()
  def generate_log_content(image_upload) do
    {path, log_file} = open_log_file(image_upload)

    image_upload
    |> prepare_log_entries()
    |> write_log_entries_to_file(log_file)
    |> Stream.run()

    FlatFileUtils.close_file(log_file)

    path
  end

  defp write_log_entries_to_file(log_entries, log_file) do
    log_entries
    |> CSV.encode(separator: ?,, headers: @file_headers)
    |> Stream.each(&IO.write(log_file, &1))
  end

  defp prepare_log_entries(image_upload) do
    Stream.concat([
      Stream.map(image_upload.invalid_file_infos || [], fn %{
                                                             "filename" => filename,
                                                             "reason" => reason
                                                           } ->
        %{filename: filename, status: "not uploaded", message: reason, matched_attribute: ""}
      end),
      Stream.map(image_upload.mapped_images, fn image ->
        image = Ash.load!(image, [:attachment, :record], tenant: image_upload.collection_id)

        %{
          filename: image.attachment.filename,
          status: "mapped",
          message: "",
          matched_attribute: Map.get(image.record, image.mapping_identifier, "")
        }
      end),
      Stream.map(image_upload.unmapped_images, fn image ->
        image = Ash.load!(image, [:attachment, :record], tenant: image_upload.collection_id)

        %{
          filename: image.attachment.filename,
          status: "unmapped",
          message: "",
          matched_attribute: ""
        }
      end)
    ])
  end

  defp open_log_file(image_upload) do
    directory_path = FlatFileUtils.create_directory!("image_upload_logs")

    path = directory_path <> "/image_upload_log-#{image_upload.id}-#{Uniq.UUID.uuid7(:slug)}.csv"

    {path,
     File.open!(path, [
       :write,
       :utf8
     ])}
  end
end
