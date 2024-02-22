defmodule DataAggregator.Files.CacheTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Cache

  @example "test/support/fixtures/files/museum-dataset-import-example.csv"

  test "store/1" do
    {:ok, attachment} = Attachment.import_from_path(@example)
    {:ok, path} = Cache.store(attachment)

    assert File.exists?(path)
    assert Cache.cached?(attachment) == true
    assert file_hash(path) == file_hash(@example)
  end

  test "delete/1" do
    {:ok, attachment} = Attachment.import_from_path(@example)
    {:ok, path} = Cache.store(attachment)

    assert File.exists?(path)
    assert Cache.cached?(attachment) == true

    assert_deletes_file path do
      assert :ok == Cache.delete(attachment)
    end

    assert Cache.cached?(attachment) == false
  end

  defp file_hash(path) do
    hash = :crypto.hash_init(:md5)

    path
    |> File.stream!(2048, [])
    |> Enum.reduce(hash, &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16()
  end
end
