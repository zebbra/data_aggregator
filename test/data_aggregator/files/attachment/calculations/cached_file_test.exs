defmodule DataAggregator.Files.Attachment.Calculations.CachedFileTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Files
  alias DataAggregator.Files.Attachment

  @example "test/support/fixtures/files/museum-dataset-import-example.csv"

  test "load calculation" do
    {:ok, attachment} = Attachment.import_from_path(@example)
    {:ok, attachment} = Files.load(attachment, :cached_file)

    assert String.ends_with?(attachment.cached_file, "museum-dataset-import-example.csv")
    assert File.exists?(attachment.cached_file)
  end
end
