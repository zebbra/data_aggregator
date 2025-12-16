defmodule DataAggregator.Files.AttachmentTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  alias DataAggregator.Files.Attachment
  alias DataAggregator.RecordsFixtures

  @example_file "test/support/fixtures/files/gbifch_swiss-species-registry-small.csv"

  setup do
    collection = RecordsFixtures.collection_fixture()

    [collection: collection]
  end

  test "import from path", %{collection: collection} do
    {:ok, attachment} = Attachment.import_from_path(@example_file, collection)

    assert attachment.url ==
             "http://localhost:4002/files/#{attachment.id}/gbifch_swiss-species-registry-small.csv"
  end

  test "import from invalid path", %{collection: collection} do
    {:error, error} = Attachment.import_from_path("this-is-invalid.zip", collection)

    assert_has_error(
      error.changeset,
      Ash.Error.Invalid,
      &(&1.message == "path is invalid")
    )
  end

  test "destroy also (soft) deletes file", %{collection: collection} do
    {:ok, attachment} = Attachment.import_from_path(@example_file, collection)

    conn = get(build_conn(), attachment.url)

    assert conn.status == 200

    assert {:ok, %{deleted?: true}} =
             Attachment.destroy(attachment, load: [:deleted?])

    conn = get(build_conn(), attachment.url)

    # the attachment still exists, because it's only soft-deleted
    assert conn.status == 200
  end

  test "destroy soft-deletes file and hard_destroy deletes it for good", %{collection: collection} do
    {:ok, attachment} = Attachment.import_from_path(@example_file, collection)

    assert {:ok, attachment} = Attachment.destroy(attachment, load: [:deleted?])

    assert attachment.deleted? == true

    assert {:ok, attachments} = Attachment.read_deleted()
    assert length(attachments) == 1

    assert :ok = Attachment.hard_destroy!(attachment)

    conn = get(build_conn(), attachment.url)

    # the attachment is now hard-deleted
    assert conn.status == 404
  end
end
