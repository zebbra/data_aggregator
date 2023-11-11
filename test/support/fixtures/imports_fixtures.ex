defmodule DataAggregator.RecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @record_defaults %{
    mte_material_entity_id: "record1",
    tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
  }

  @collection_defaults %{
    name: "Collection",
    owner: "Max Powers"
  }

  @doc """
  Generate a record.
  """
  def record_fixture(attrs \\ %{}) do
    @record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  def collection_fixture(attrs \\ %{}) do
    @collection_defaults
    |> Map.merge(attrs)
    |> Collection.create!()
  end
end
