defmodule DataAggregator.Records.ImageUpload.Helpers do
  @moduledoc false

  @accepted_image_extensions ~w(.jpg .jpeg .png .bmp .tiff .svg .webp)
  def accepted_image_extensions, do: @accepted_image_extensions

  @max_image_size 5_242_880
  def max_image_size, do: @max_image_size

  def construct_associated_media(nil, image) do
    image |> Ash.load!(:image_url) |> Map.get(:image_url)
  end

  def construct_associated_media(original_associated_media, image) do
    image_url = image |> Ash.load!(:image_url) |> Map.get(:image_url)

    if String.contains?(original_associated_media, image_url) do
      original_associated_media
    else
      maybe_concatenate(original_associated_media, image_url)
    end
  end

  defp maybe_concatenate(associated_media, new_url) do
    case associated_media do
      "" -> new_url
      _ -> "#{associated_media} | #{new_url}"
    end
  end
end
