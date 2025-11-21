defmodule DataAggregator.Files.AttachmentTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Workers.AttachmentDeleter

  @example_file "test/support/fixtures/files/gbifch_swiss-species-registry-small.csv"

  test "import from path" do
    {:ok, attachment} = Attachment.import_from_path(@example_file)

    assert attachment.url ==
             "http://localhost:4002/files/#{attachment.id}/gbifch_swiss-species-registry-small.csv"
  end

  test "import from invalid path" do
    {:error, error} = Attachment.import_from_path("this-is-invalid.zip")

    assert_has_error(
      error.changeset,
      Ash.Error.Invalid,
      &(&1.message == "path is invalid")
    )
  end

  test "destroy also (soft) deletes file" do
    {:ok, attachment} = Attachment.import_from_path(@example_file)

    conn = get(build_conn(), attachment.url)

    assert conn.status == 200
    assert {:ok, %Attachment{deletable: true}} = Attachment.destroy(attachment)

    conn = get(build_conn(), attachment.url)

    # the attachment still exists, because it's only soft-deleted
    assert conn.status == 200
  end

  test "destroy (soft) deletes file and oban-worker hard_deletes it" do
    {:ok, attachment} = Attachment.import_from_path(@example_file)

    assert {:ok, %Attachment{deletable: true}} = Attachment.destroy(attachment)

    :ok = AttachmentDeleter.perform(%Oban.Job{id: "my-id", meta: %{"cron" => true}})

    conn = get(build_conn(), attachment.url)

    # the attachment is now hard-deleted
    assert conn.status == 404
  end
end
