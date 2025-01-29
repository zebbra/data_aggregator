defmodule DataAggregator.Records.ImageUpload.Helpers do
  @moduledoc """
  Helper functions for image uploads.
  """

  @accepted_image_extensions ~w(.jpg .jpeg .png .bmp .tiff .svg .webp)
  def accepted_image_extensions, do: @accepted_image_extensions

  @max_image_size 5_242_880
  def max_image_size, do: @max_image_size

  @doc """
  Constructs the associated media string for the given image and original/current associated media.
  """
  @spec construct_associated_media(String.t(), map()) :: String.t()
  def construct_associated_media(nil, image) do
    image |> Ash.load!(:image_url, lazy?: true) |> Map.get(:image_url)
  end

  def construct_associated_media(original_associated_media, image) do
    image_url = image |> Ash.load!(:image_url, lazy?: true) |> Map.get(:image_url, "")

    if String.contains?(original_associated_media, image_url) do
      original_associated_media
    else
      maybe_concatenate(original_associated_media, image_url)
    end
  end

  @doc """
  Returns the content-type (e.g. to be used as response header) for the given image file extension.

  ## Examples

      iex> accepted_image_content_type(".jpg")
      "image/jpeg"

      iex> accepted_image_content_type(".jpeg")
      "image/jpeg"

      iex> accepted_image_content_type(".png")
      "image/png"

      iex> accepted_image_content_type(".bmp")
      "image/bmp"

      iex> accepted_image_content_type(".tiff")
      "image/tiff"

      iex> accepted_image_content_type(".svg")
      "image/svg+xml"

      iex> accepted_image_content_type(".webp")
      "image/webp"

      iex> accepted_image_content_type(".something")
      "application/octet-stream"
  """
  @spec accepted_image_content_type(String.t()) :: String.t()
  def accepted_image_content_type(file_extension) do
    case file_extension do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".bmp" -> "image/bmp"
      ".tiff" -> "image/tiff"
      ".svg" -> "image/svg+xml"
      ".webp" -> "image/webp"
      _ -> "application/octet-stream"
    end
  end

  defp maybe_concatenate(associated_media, ""), do: associated_media
  defp maybe_concatenate("", new_url), do: new_url
  defp maybe_concatenate(associated_media, new_url), do: "#{associated_media} | #{new_url}"
end
