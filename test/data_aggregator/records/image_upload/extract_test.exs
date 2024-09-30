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

    [
      collection: collection,
      image_upload: image_upload
    ]
  end

  test "extract/1 successful", %{
    image_upload: image_upload
  } do
    assert {:ok, image_upload} = ImageUpload.extract(image_upload)

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
end
