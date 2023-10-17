defmodule DataAggregator.ImportRecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Imports` context.
  """

  alias DataAggregator.Imports.ImportRecord

  @doc """
  Generate a import_record.
  """
  def import_record_fixture(attrs \\ %{}) do
    {:ok, import_record} =
      attrs
      |> Enum.into(%{
        unique_qualifier: "import_record1"
      })
      |> ImportRecord.create()

    ImportRecord.get_by_id!(import_record.id)
  end
end
