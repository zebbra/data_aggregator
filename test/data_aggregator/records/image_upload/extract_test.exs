defmodule DataAggregator.Records.ImageUpload.ExtractTest do
  @moduledoc false

  use DataAggregator.DataCase
  use Mimic

  import DataAggregator.ImageUploadFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.ImageUpload

  setup do
    collection = collection_fixture(%{name: "Extract Test Collection"})

    image_upload =
      image_upload_fixture(collection)

    image_upload_with_invalid_files =
      image_upload_fixture(collection, %{
        path: "test/support/fixtures/files/image_upload_test_catalog_number_invalid_files.zip"
      })

    image_upload_mac_hidden_files =
      image_upload_fixture(collection, %{
        path: "test/support/fixtures/files/mac_hidden_files.zip"
      })

    image_upload_osx_zipped_folder =
      image_upload_fixture(collection, %{
        path: "test/support/fixtures/files/mac_zip_folder.zip"
      })

    [
      collection: collection,
      image_upload: image_upload,
      image_upload_with_invalid_files: image_upload_with_invalid_files,
      image_upload_mac_hidden_files: image_upload_mac_hidden_files,
      image_upload_osx_zipped_folder: image_upload_osx_zipped_folder
    ]
  end

  test "extract/1 successful", %{
    image_upload: image_upload
  } do
    assert {:ok, image_upload} = ImageUpload.extract(image_upload)

    assert image_upload.invalid_file_infos == []

    assert image_upload.state == :extracted
    assert image_upload.image_attachments != nil
    assert is_list(image_upload.image_attachments)
    assert length(image_upload.image_attachments) == 5

    assert image_upload.images != nil
    image_upload = Ash.load!(image_upload, :images)

    Enum.each(image_upload.image_attachments, fn image_attachment ->
      assert image_attachment.url != nil

      assert image_attachment.filename in [
               "catalogNumber1_1.jpg",
               "catalogNumber1_2.jpg",
               "catalogNumber2.jpg",
               "catalogNumber4.jpeg",
               "catalogNumber1337_noMatch.jpg"
             ]
    end)

    Enum.each(image_upload.images, fn image ->
      assert image.attachment_id != nil
      assert image.image_upload_id == image_upload.id
    end)
  end

  test "extract/1 successful with part of the zipped files invalid", %{
    image_upload_with_invalid_files: image_upload
  } do
    assert {:ok, image_upload} = ImageUpload.extract(image_upload)

    assert image_upload.invalid_file_infos != nil
    assert is_list(image_upload.invalid_file_infos)
    assert length(image_upload.invalid_file_infos) == 2

    Enum.each(image_upload.invalid_file_infos, fn invalid_file_info ->
      case invalid_file_info["filename"] do
        "image_too_big_10MB.jpg" ->
          assert invalid_file_info["reason"] == "file_size"

        "collection-import-m.csv" ->
          assert invalid_file_info["reason"] == "file_extension"
      end
    end)

    assert image_upload.state == :extracted
    assert image_upload.image_attachments != nil
    assert is_list(image_upload.image_attachments)
    assert length(image_upload.image_attachments) == 1

    assert image_upload.images != nil
    image_upload = Ash.load!(image_upload, :images)

    Enum.each(image_upload.image_attachments, fn image_attachment ->
      assert image_attachment.url != nil
      assert image_attachment.filename == "catalogNumber1_1.jpg"
    end)
  end

  test "extract/1 successful with zip file containing hidden OSX file filtered out", %{
    image_upload_mac_hidden_files: image_upload
  } do
    assert {:ok, image_upload} = ImageUpload.extract(image_upload)

    assert image_upload.invalid_file_infos == []

    assert image_upload.state == :extracted
    assert image_upload.image_attachments != nil
    assert is_list(image_upload.image_attachments)
    assert length(image_upload.image_attachments) == 5

    assert image_upload.images != nil
    image_upload = Ash.load!(image_upload, :images)

    Enum.each(image_upload.image_attachments, fn image_attachment ->
      assert image_attachment.url != nil

      assert image_attachment.filename in [
               "GBIFCH00993799_1.jpg",
               "GBIFCH00993799_2.jpg",
               "GBIFCH00993760.jpeg",
               "GBIFCH00993789.jpg",
               "occurrenceID1337_noMatch.jpg"
             ]
    end)
  end

  test "extract/1 successful with zip file containing zipped OSX folder with files", %{
    image_upload_osx_zipped_folder: image_upload
  } do
    assert {:ok, image_upload} = ImageUpload.extract(image_upload)

    assert image_upload.invalid_file_infos == []

    assert image_upload.state == :extracted
    assert image_upload.image_attachments != nil
    assert is_list(image_upload.image_attachments)
    assert length(image_upload.image_attachments) == 5

    assert image_upload.images != nil
    image_upload = Ash.load!(image_upload, :images)

    Enum.each(image_upload.image_attachments, fn image_attachment ->
      assert image_attachment.url != nil

      assert image_attachment.filename in [
               "GBIFCH00993799_1.jpg",
               "GBIFCH00993799_2.jpg",
               "GBIFCH00993760.jpeg",
               "GBIFCH00993789.jpg",
               "occurrenceID1337_noMatch.jpg"
             ]
    end)
  end
end
