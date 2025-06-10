defmodule DataAggregator.Files.Attachment.Helpers do
  @moduledoc """
  Helper functions for file attachments.
  """

  @doc """
  Returns a public valid url for file attachments
  """
  def attachment_public_url(attachment_id) do
    "BASE_URL"
    |> System.get_env("http://localhost:4000")
    |> URI.parse()
    |> URI.append_path("/attachments")
    |> URI.append_path("/#{attachment_id}")
    |> URI.append_path("/download")
    |> URI.to_string()
  end
end
