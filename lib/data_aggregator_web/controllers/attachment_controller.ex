defmodule DataAggregatorWeb.AttachmentController do
  @moduledoc """
  Controller for handling file attachment serving and downloads.

  This controller provides endpoints to serve and download file attachments
  stored via the `DataAggregator.Files.Attachment` resource.

  ## Routes

  - `GET /attachments/:id` - Serves the attachment inline (for viewing in browser)
  - `GET /attachments/:id/download` - Forces download of the attachment

  ## Examples

      # Serve an attachment inline (for viewing)
      GET /attachments/fat_abc123

      # Download an attachment
      GET /attachments/fat_abc123/download

  ## Content Type Detection

  The controller automatically detects content types based on file extensions:
  - `.pdf` → `application/pdf`
  - `.csv` → `text/csv`
  - `.json` → `application/json`
  - `.jpg/.jpeg` → `image/jpeg`
  - `.png` → `image/png`
  - And many more...

  Unknown file types default to `application/octet-stream`.

  ## Security

  - Files are served through signed URLs from the configured storage backend
  - Filenames are sanitized for safe downloads
  - Proper Content-Disposition headers are set for downloads
  """

  use DataAggregatorWeb, :controller

  alias DataAggregator.Files.Attachment

  require Logger

  @doc """
  Serves a file attachment by ID
  """
  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => attachment_id}) do
    case Attachment.get_by_id(attachment_id, load: [:url]) do
      {:error, error} ->
        Logger.debug("Error while retrieving attachment: #{inspect(error)}")

        conn
        |> put_status(:not_found)
        |> text("Unable to find the requested attachment")

      {:ok, attachment} ->
        serve_attachment(attachment, conn, :inline)
    end
  end

  @doc """
  Downloads a file attachment by ID
  """
  @spec download(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def download(conn, %{"id" => attachment_id}) do
    case Attachment.get_by_id(attachment_id, load: [:url]) do
      {:error, error} ->
        Logger.debug("Error while retrieving attachment: #{inspect(error)}")

        conn
        |> put_status(:not_found)
        |> text("Unable to find the requested attachment")

      {:ok, attachment} ->
        serve_attachment(attachment, conn, :attachment)
    end
  end

  defp serve_attachment(attachment, conn, disposition) do
    case Req.get(url: attachment.url, raw: true) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        content_type = guess_content_type(attachment.filename)
        disposition_value = build_disposition(disposition, attachment.filename)

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("content-disposition", disposition_value)
        |> send_resp(200, body)

      {:ok, %Req.Response{status: status}} ->
        Logger.debug("Non http 200 status while requesting file from storage: #{status}")

        conn
        |> put_status(status)
        |> text("Could not find the requested file")

      {:error, reason} ->
        Logger.debug("Error while retrieving file from storage: #{inspect(reason)}")

        conn
        |> put_status(:bad_gateway)
        |> text("Could not find the requested file")
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp guess_content_type(filename) do
    case filename |> Path.extname() |> String.downcase() do
      ".pdf" -> "application/pdf"
      ".txt" -> "text/plain"
      ".csv" -> "text/csv"
      ".json" -> "application/json"
      ".xml" -> "application/xml"
      ".zip" -> "application/zip"
      ".doc" -> "application/msword"
      ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ".xls" -> "application/vnd.ms-excel"
      ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".svg" -> "image/svg+xml"
      ".mp4" -> "video/mp4"
      ".mp3" -> "audio/mpeg"
      ".wav" -> "audio/wav"
      _ -> "application/octet-stream"
    end
  end

  defp build_disposition(:inline, _filename), do: "inline"

  defp build_disposition(:attachment, filename) do
    safe_filename =
      filename
      |> String.replace(~r/[^\w\-_\.]/, "_")
      |> URI.encode()

    "attachment; filename=\"#{safe_filename}\""
  end
end
