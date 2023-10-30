defmodule DataAggregator.RecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Data` context.
  """

  alias DataAggregator.Data.Record

  @doc """
  Generate a record.
  """
  def record_fixture(attrs \\ %{}) do
    {:ok, record} =
      attrs
      |> Enum.into(%{
        materialEntityID: "record1",
        scientificName: "06809dc5-f143-459a-be1a-6f03e63fc083"
      })
      |> Record.create()

    Record.get_by_id!(record.id)
  end
end
