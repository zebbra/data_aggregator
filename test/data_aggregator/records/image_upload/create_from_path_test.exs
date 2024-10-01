defmodule DataAggregator.Records.ImageUpload.CreateFromPathTest do
  @moduledoc false

  use DataAggregator.DataCase
  use Mimic

  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Records.ImageUpload

  setup do
    collection = collection_fixture(%{name: "Create From Path Test Collection"})

    [
      collection: collection
    ]
  end

  test "create_from_path/2 successful", %{
    collection: collection
  } do
    assert {:ok, image_upload} =
             ImageUpload.create_from_path(
               collection,
               "test/support/fixtures/files/image_upload_test_catalog_number.zip"
             )

    assert image_upload.state == :new
    assert image_upload.attachment_id != nil
    assert image_upload.attachment.filename == "image_upload_test_catalog_number.zip"
  end

  test "create_from_path/2 fails with invalid path", %{
    collection: collection
  } do
    assert {:error, %Invalid{errors: errors}} =
             ImageUpload.create_from_path(
               collection,
               "test/support/fixtures/files/invalid.zip"
             )

    assert Enum.any?(errors, fn error ->
             String.contains?(error.message, "Could not read file")
           end)
  end

  test "create_from_path/2 fails with invalid file", %{
    collection: collection
  } do
    assert {:error, %Invalid{errors: errors}} =
             ImageUpload.create_from_path(
               collection,
               "test/support/fixtures/files/extracted_images/catalogNumber1_1.jpg"
             )

    assert Enum.any?(errors, fn error ->
             String.contains?(error.message, "Error listing files")
           end)
  end
end
