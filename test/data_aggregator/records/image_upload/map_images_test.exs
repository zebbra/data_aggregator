defmodule DataAggregator.Records.ImageUpload.MapImagesTest do
  @moduledoc false

  use DataAggregator.DataCase
  use Mimic

  import DataAggregator.ImageUploadFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Files.Attachment
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

    image_upload_complete =
      image_upload_fixture_extracted_complete(collection)

    [
      image_upload: image_upload,
      image_upload_complete: image_upload_complete,
      collection: collection
    ]
  end

  test "map/1 successful with complete mapping", %{
    image_upload_complete: image_upload,
    collection: collection
  } do
    assert {:ok, image_upload} = ImageUpload.map(image_upload, tenant: collection)

    assert image_upload.state == :mapped

    image_upload =
      Ash.load!(
        image_upload,
        [:mapped_images, images: [attachment: :filename]]
      )

    assert "catalogNumber1_1.jpg" in images_to_assert(image_upload.mapped_images)
    assert "catalogNumber1_2.jpg" in images_to_assert(image_upload.mapped_images)
    assert "catalogNumber2.jpg" in images_to_assert(image_upload.mapped_images)
    assert "catalogNumber4.jpeg" in images_to_assert(image_upload.mapped_images)
  end

  @tag timeout: :infinity
  test "map/1 successful with incomplete mapping", %{
    image_upload: image_upload,
    collection: collection
  } do
    assert {:ok, image_upload} = ImageUpload.map(image_upload, tenant: collection)

    assert image_upload.state == :mapping_incomplete

    assert image_upload.mapped_images_count === 4
    assert image_upload.unmapped_images_count === 1
    assert image_upload.current_mapping_operations_count === 5

    image_upload =
      Ash.load!(image_upload, [:mapped_images, :unmapped_images, images: [attachment: :filename]])

    collection =
      Ash.load!(
        collection,
        [records: [:image_attachments, :encoded_record, images: :image_url]],
        tenant: collection
      )

    assert "catalogNumber1_1.jpg" in images_to_assert(image_upload.mapped_images)
    assert "catalogNumber1_2.jpg" in images_to_assert(image_upload.mapped_images)
    assert "catalogNumber2.jpg" in images_to_assert(image_upload.mapped_images)
    assert "catalogNumber4.jpeg" in images_to_assert(image_upload.mapped_images)

    assert "catalogNumber1337_noMatch.jpg" in images_to_assert(image_upload.unmapped_images)

    Enum.each(collection.records, fn record ->
      case record.mte_catalog_number do
        "catalogNumber1" ->
          assert length(record.images) == 2
          assert length(record.image_attachments) == 2

          Enum.each(record.images, fn image ->
            assert String.contains?(
                     record.encoded_record.mte_associated_media,
                     image.image_url
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
                     image.image_url
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
                     image.image_url
                   )
          end)

          assert record.image_attachments |> List.first() |> Map.get(:filename) ==
                   "catalogNumber4.jpeg"
      end
    end)
  end

  defp images_to_assert(images) do
    Enum.map(images, fn image -> image.attachment.filename end)
  end

  test "map/1 check if log is present after mapping", %{
    image_upload_complete: image_upload,
    collection: collection
  } do
    assert {:ok, image_upload} = ImageUpload.map(image_upload, tenant: collection)

    assert image_upload.state == :mapped
    assert image_upload.mapped_images_count === 4
    assert image_upload.unmapped_images_count === 0
    assert image_upload.current_mapping_operations_count === 4

    image_upload =
      Ash.load!(
        image_upload,
        [:upload_log]
      )

    assert %Attachment{} = image_upload.upload_log
    assert image_upload.upload_log.url

    df = Explorer.DataFrame.from_csv!(image_upload.upload_log.url, infer_schema_length: 0)

    assert Explorer.DataFrame.n_columns(df) == 4
    assert Explorer.DataFrame.n_rows(df) == 4
  end
end
