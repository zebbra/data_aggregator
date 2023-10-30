defmodule DataAggregator.Files.AttachmentTest do
  use DataAggregatorWeb.ConnCase

  alias DataAggregator.Files.Attachment

  test "import from path" do
    {:ok, attachment} = Attachment.import_from_path("seed/gchdata-thesaurus.xlsx.zip")

    assert attachment.url ==
             "http://localhost:4002/files/#{attachment.id}/gchdata-thesaurus.xlsx.zip"
  end

  test "import from invalid path" do
    {:error, error} = Attachment.import_from_path("seed/this-is-invalid.zip")

    assert_has_error(
      error.changeset,
      Ash.Error.Invalid,
      &(&1.message == "path is invalid")
    )
  end

  test "destroy also deletes file" do
    {:ok, attachment} = Attachment.import_from_path("seed/gchdata-thesaurus.xlsx.zip")

    conn = get(build_conn(), attachment.url)
    assert conn.status == 200

    assert :ok = Attachment.destroy(attachment)

    conn = get(build_conn(), attachment.url)
    assert conn.status == 404
  end
end
