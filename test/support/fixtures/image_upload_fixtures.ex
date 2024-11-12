defmodule DataAggregator.ImageUploadFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records.ImageUpload

  @image_upload_defaults %{
    filename: "image_upload_test.zip",
    path: "test/support/fixtures/files/image_upload_test_catalog_number.zip",
    state: :new
  }

  @doc """
  Generate a image_upload
  """
  def image_upload_fixture(collection, attrs \\ %{}) do
    attrs = Map.merge(@image_upload_defaults, attrs)
    ImageUpload.create_from_path!(collection, attrs[:path], tenant: collection)
  end

  @doc """
  Generate an image_upload with extracted files and state
  """
  def image_upload_fixture_extracted(collection, attrs \\ %{}) do
    collection |> image_upload_fixture(attrs) |> ImageUpload.extract!()
  end

  @doc """
  Generate an image_upload with mapped images
  """
  def image_upload_fixture_mapped(collection, attrs \\ %{mapping_identifier: :mte_catalog_number}) do
    collection
    |> image_upload_fixture(attrs)
    |> ImageUpload.extract!()
    |> ImageUpload.update_mapping_identifier!(attrs[:mapping_identifier])
    |> ImageUpload.map!(tenant: collection)
  end
end
