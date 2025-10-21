defmodule DataAggregator.Records.Encoding.RelateImagesTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ImageUploadFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "relate images encoding of records with " do
    setup do
      collection = collection_fixture(%{name: "Relate Images Test Collection"})

      record_fixture =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber1"
        })

      record_fixture_no_mapping =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumberNoMapping"
        })

      image_upload = image_upload_fixture_mapped(collection)

      [
        image_upload: image_upload,
        collection: collection,
        record_fixture: record_fixture,
        record_fixture_no_mapping: record_fixture_no_mapping
      ]
    end

    test "encode/2 for :relate_images catalog - don't relate images if no images - successful",
         %{
           record_fixture_no_mapping: record
         } do
      record = Ash.load!(record, [:encoded_record, images: [:attachment, :image_url]])

      assert record.images == []
      assert record.encoded_record.mte_associated_media == nil

      {:ok, record} =
        Record.encode(record, :relate_images, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)

      assert record.encoded_record.mte_associated_media == nil
    end

    test "encode/2 for :relate_images catalog - relate images, don't change already added associated_media - successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        Ash.load!(record_fixture, [:encoded_record, images: [:attachment, :image_url]])

      Enum.each(record_fixture.images, fn image ->
        assert String.contains?(
                 record_fixture.encoded_record.mte_associated_media,
                 image.image_url
               )
      end)

      {:ok, record} =
        Record.encode(record_fixture, :relate_images, tenant: record_fixture.collection_id)

      record = Ash.load!(record, [:encoded_record, images: [:attachment, :image_url]])

      assert record.encoded_record.mte_associated_media

      assert record.encoded_record.mte_associated_media |> String.split(" | ") |> length() ==
               length(record.images)

      Enum.each(record.images, fn image ->
        assert String.contains?(
                 record.encoded_record.mte_associated_media,
                 image.image_url
               )
      end)
    end

    test "encode/2 for :relate_images catalog - relate images, add correct associated media when empty - successful",
         %{
           record_fixture: record
         } do
      record = Ash.load!(record, :encoded_record)

      EncodedRecord.update!(record.encoded_record, %{mte_associated_media: ""})

      record = Ash.load!(record, [:encoded_record, images: :attachment])
      assert record.encoded_record.mte_associated_media == nil
      assert length(record.images) == 2

      {:ok, record} =
        Record.encode(record, :relate_images, tenant: record.collection_id)

      record = Ash.load!(record, [:encoded_record, images: [:attachment, :image_url]])

      assert record.encoded_record.mte_associated_media

      assert record.encoded_record.mte_associated_media |> String.split(" | ") |> length() ==
               length(record.images)

      Enum.each(record.images, fn image ->
        assert String.contains?(
                 record.encoded_record.mte_associated_media,
                 image.image_url
               )
      end)
    end
  end
end
