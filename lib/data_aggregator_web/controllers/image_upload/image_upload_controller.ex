defmodule DataAggregatorWeb.ImageUploadController do
  @moduledoc """
  Controller for handling image uploads and retrievals
  """

  use DataAggregatorWeb, :controller

  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Helpers
  alias DataAggregator.Records.Record.Image

  require Logger

  @doc """
  Serves an image hosted on our static asset storage server over http
  """
  @spec show_image(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show_image(conn, %{"collection_id" => collection_id, "image_id" => image_id}) do
    case Image.get_by_id(image_id, load: [attachment: :url], tenant: collection_id) do
      {:error, error} ->
        Logger.debug("Error while retrieving image: #{inspect(error)}")

        conn
        |> put_status(:not_found)
        |> text(~c"Unable to find the requested image")

      {:ok, image} ->
        serve_image(image.attachment.url, conn)
    end
  end

  @doc """
  Downloads the log file for an image upload
  """
  @spec download_log(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def download_log(conn, %{"image_upload_id" => id, "id" => collection_id}) do
    case ImageUpload.get_by_id(id,
           load: [
             :mapped_images,
             :unmapped_images
           ],
           tenant: collection_id
         ) do
      {:error, error} ->
        Logger.debug("Error while retrieving image: #{inspect(error)}")

        conn
        |> put_status(:not_found)
        |> text(~c"Unable to find the requested image")

      {:ok, image_upload} ->
        log_content = generate_log_content(image_upload)

        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("content-disposition", "attachment; filename=\"image_upload_log.csv\"")
        |> send_resp(200, log_content)
    end
  end

  defp serve_image(url, conn) do
    case Req.get(url: url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        content_type = guess_image_content_type(url)

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("content-disposition", "inline")
        |> send_resp(200, body)

      {:ok, %Req.Response{status: status}} ->
        Logger.debug("Non http 200 status while requesting file from static asset storage: #{status}")

        conn
        |> put_status(status)
        |> text("Could not find the requested file")

      {:error, reason} ->
        Logger.debug("Error while retrieving file from static asset storage: #{inspect(reason)}")

        conn
        |> put_status(:bad_gateway)
        |> text("Could not find the requested file")
    end
  end

  defp guess_image_content_type(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> Path.extname()
    |> Helpers.accepted_image_content_type()
  end

  defp generate_log_content(image_upload) do
    # CSV Header
    log = "Filename,Status,Message,Matched Attribute\n"

    log =
      Enum.reduce(image_upload.invalid_file_infos || [], log, fn %{
                                                                   "filename" => filename,
                                                                   "reason" => reason
                                                                 },
                                                                 acc ->
        "#{acc}#{filename},not uploaded,#{reason},\n"
      end)

    log =
      Enum.reduce(image_upload.mapped_images, log, fn {filename, matched_attribute}, acc ->
        "#{acc}#{filename},mapped,,#{matched_attribute}\n"
      end)

    Enum.reduce(image_upload.unmapped_images, log, fn filename, acc ->
      "#{acc}#{filename},unmapped,\n"
    end)
  end
end
