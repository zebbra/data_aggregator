defmodule DataAggregator.Records.ImageUpload.MapImagesTest do
  @moduledoc false

  use DataAggregator.DataCase
  use Mimic

  import DataAggregator.ImageUploadFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.ImageUpload

  setup do
    collection = collection_fixture(%{name: "Map Image Test Collection"})

    record_fixture(%{
      collection: collection,
      mte_catalog_number: "catalogNumber1"
    })

    record_fixture(%{
      collection: collection,
      mte_catalog_number: "catalogNumber2"
    })

    record_fixture(%{
      collection: collection,
      mte_catalog_number: "catalogNumber3"
    })

    record_fixture(%{
      collection: collection,
      mte_catalog_number: "catalogNumber4"
    })

    image_upload =
      image_upload_fixture_extracted(collection)

    [
      image_upload: image_upload,
      collection: collection
    ]
  end

  @tag timeout: :infinity
  test "map/1 successful", %{
    image_upload: image_upload,
    collection: collection
  } do
    assert {:ok, image_upload} = ImageUpload.map(image_upload, tenant: collection)

    image_upload = Ash.load!(image_upload, [:images, :mapped_images, :unmapped_images])

    collection =
      Ash.load!(collection, [records: [:images, :image_attachments, :encoded_record]], tenant: collection)

    assert {"catalogNumber1_1.jpg", "catalogNumber1"} in image_upload.mapped_images
    assert {"catalogNumber1_2.jpg", "catalogNumber1"} in image_upload.mapped_images
    assert {"catalogNumber2.jpg", "catalogNumber2"} in image_upload.mapped_images
    assert {"catalogNumber4.jpeg", "catalogNumber4"} in image_upload.mapped_images

    assert "catalogNumber1337_noMatch.jpg" in image_upload.unmapped_images

    Enum.each(collection.records, fn record ->
      case record.mte_catalog_number do
        "catalogNumber1" ->
          assert length(record.images) == 2
          assert length(record.image_attachments) == 2

          Enum.each(record.images, fn image ->
            assert String.contains?(
                     record.encoded_record.mte_associated_media,
                     System.get_env("BASE_URL") <>
                       "/collections/" <>
                       record.collection_id <> "/image_uploads/images/" <> image.id
                   )
          end)

          Enum.each(record.image_attachments, fn image_attachment ->
            assert image_attachment.filename in ["catalogNumber1_1.jpg", "catalogNumber1_2.jpg"]
          end)

        "catalogNumber2" ->
          assert length(record.images) == 1
          assert length(record.image_attachments) == 1

          Enum.each(record.images, fn image ->
            assert String.contains?(
                     record.encoded_record.mte_associated_media,
                     System.get_env("BASE_URL") <>
                       "/collections/" <>
                       record.collection_id <> "/image_uploads/images/" <> image.id
                   )
          end)

          assert record.image_attachments |> List.first() |> Map.get(:filename) ==
                   "catalogNumber2.jpg"

        "catalogNumber3" ->
          assert Enum.empty?(record.images)
          assert Enum.empty?(record.image_attachments)

          refute record.encoded_record.mte_associated_media

        "catalogNumber4" ->
          assert length(record.images) == 1
          assert length(record.image_attachments) == 1

          Enum.each(record.images, fn image ->
            assert String.contains?(
                     record.encoded_record.mte_associated_media,
                     System.get_env("BASE_URL") <>
                       "/collections/" <>
                       record.collection_id <> "/image_uploads/images/" <> image.id
                   )
          end)

          assert record.image_attachments |> List.first() |> Map.get(:filename) ==
                   "catalogNumber4.jpeg"
      end
    end)
  end
end
