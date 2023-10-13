defmodule DataAggregator.ImportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Imports` context.
  """

  alias DataAggregator.Imports.Import
  alias DataAggregator.Imports.ImportFile

  @doc """
  Generate a import.
  """
  def import_fixture(attrs \\ %{}) do
    {:ok, import} =
      attrs
      |> Enum.into(%{
        name: "import1",
        version: 1,
        collection_id: "496752bc-6743-11ee-8c99-0242ac120002"
      })
      |> Import.create()

    Import.get_by_id!(import.id)
  end

  @doc """
  Generate a import_file.
  """
  def import_file_fixture(attrs \\ %{}) do
    {:ok, import_file} =
      attrs
      |> Enum.into(%{
        import: %{id: "496752bc-6743-11ee-8c99-0242ac120042"},
        meta_data: "{}",
        url: "https://example.com/my_file_1.csv"
      })
      |> ImportFile.create()

    ImportFile.get_by_id!(import_file.id)
  end
end
