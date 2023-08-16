defmodule DataAggregator.ImportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Imports` context.
  """

  alias DataAggregator.Imports.Import

  @doc """
  Generate a import.
  """
  def import_fixture(attrs \\ %{}) do
    {:ok, import} =
      attrs
      |> Enum.into(%{url: "https://example.com"})
      |> Import.create()

    Import.get_by_id!(import.id)
  end
end
