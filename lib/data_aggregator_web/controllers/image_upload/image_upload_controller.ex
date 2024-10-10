defmodule DataAggregatorWeb.ImageUploadController do
  use DataAggregatorWeb, :controller

  alias DataAggregator.Records.ImageUpload

  def download_log(conn, %{"image_upload_id" => id}) do
    case ImageUpload.get_by_id(id,
           load: [
             :mapped_images,
             :unmapped_images
           ]
         ) do
      {:error, _error} ->
        put_status(conn, :not_found)

      {:ok, image_upload} ->
        log_content = generate_log_content(image_upload)

        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("content-disposition", "attachment; filename=\"image_upload_log.csv\"")
        |> send_resp(200, log_content)
    end
  end

  defp generate_log_content(image_upload) do
    # CSV Header
    log = "Filename,Status,Message\n"

    log =
      Enum.reduce(image_upload.invalid_file_infos || [], log, fn %{
                                                                   "filename" => filename,
                                                                   "reason" => reason
                                                                 },
                                                                 acc ->
        "#{acc}#{filename},not uploaded,#{reason}\n"
      end)

    log =
      Enum.reduce(image_upload.mapped_images, log, fn filename, acc ->
        "#{acc}#{filename},mapped,\n"
      end)

    Enum.reduce(image_upload.unmapped_images, log, fn filename, acc ->
      "#{acc}#{filename},unmapped,\n"
    end)
  end
end
