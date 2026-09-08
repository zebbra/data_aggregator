defmodule DataAggregator.Files.Attachment.Calculations.CachedFileTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Files.Attachment
  alias DataAggregator.RecordsFixtures

  @example "test/support/fixtures/files/museum-dataset-import-example.csv"

  test "load calculation" do
    collection = RecordsFixtures.collection_fixture()

    {:ok, attachment} = Attachment.import_from_path(@example, collection)
    {:ok, attachment} = Ash.load(attachment, :cached_file)

    assert String.ends_with?(attachment.cached_file, "museum-dataset-import-example.csv")
    assert File.exists?(attachment.cached_file)
  end
end
