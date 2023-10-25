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
        unique_qualifier: "record1"
      })
      |> Record.create()

    Record.get_by_id!(record.id)
  end
end
