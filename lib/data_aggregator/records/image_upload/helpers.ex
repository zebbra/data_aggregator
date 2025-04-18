defmodule DataAggregator.Records.ImageUpload.Helpers do
  @moduledoc """
  Helper functions for image uploads.
  """
  alias Ash.Changeset
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @doc """
  Returns the identifiers (fields of the record), which are used to map the images to the records.
  """
  def mapping_identifiers do
    %{mte_catalog_number: :catalog_number}
  end

  def accepted_image_extensions, do: ~w(.jpg .jpeg .png .bmp .tiff .svg .webp)

  def max_image_size, do: 5_242_880

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
  Returns the mapping identifiers for the image upload.

  keep in mind, if we add more mapping identifiers, we need to check if there is an index
  on the record table for this field, because if not, mapping performance is significantly decreased
  """
  @spec mapping_identifier_options() :: [{String.t(), [{String.t(), String.t()}]}]
  def mapping_identifier_options do
    Schema.attribute_options(required?: false, only: Map.values(mapping_identifiers()))
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

  @doc """
  Returns the number of images to be mapped for the given image upload.
  """
  @spec count_mappable_images(Ash.Query.t()) :: pos_integer()
  def count_mappable_images(query) do
    total_images = Ash.count!(query)

    Logger.debug("Total images to map: #{total_images}")

    total_images
  end

  @doc """
  Builds an `Ash.Query` to get the images for the given image upload.
  """
  @spec compose_mappable_image_query(ImageUpload.t()) :: Ash.Query.t()
  def compose_mappable_image_query(image_upload) do
    image_upload = Ash.load!(image_upload, [:collection], lazy?: true)

    Record.Image
    |> Ash.Query.set_tenant(image_upload.collection)
    |> Ash.Query.filter(image_upload_id == ^image_upload.id)
  end

  @doc """
  updates the image upload record with the given `:unmapped_images_count` and `:current_mapping_operations_count`
  """
  @spec update_counts(Changeset.t(), pos_integer(), pos_integer()) :: Changeset.t()
  def update_counts(changeset, mapped_images_count, total_images) do
    %Changeset{data: image_upload} = changeset

    add_progress = fn ->
      ImageUpload.update!(image_upload, %{
        unmapped_images_count: total_images - mapped_images_count,
        current_mapping_operations_count: total_images
      })
    end

    image_upload = maybe_execute_async(add_progress)

    %{changeset | data: image_upload}
  end

  # decides whenever a given function with a given timeout should be executed asynchronously
  defp maybe_execute_async(fnc, opts \\ []) do
    {timeout, _opts} = Keyword.pop(opts, :timeout, 30)

    if Records.execute_async?() do
      fnc |> Task.async() |> Task.await(to_timeout(second: timeout))
    else
      fnc.()
    end
  end

  defp maybe_concatenate(associated_media, ""), do: associated_media
  defp maybe_concatenate("", new_url), do: new_url
  defp maybe_concatenate(associated_media, new_url), do: "#{associated_media} | #{new_url}"
end
