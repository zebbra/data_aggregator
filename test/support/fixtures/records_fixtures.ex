defmodule DataAggregator.RecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @record_defaults %{
    mte_catalog_number: "record1",
    tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
  }

  @collection_defaults %{
    name: "Collection",
    owner: "Max Powers",
    type: :zoology,
    grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472",
    code: "322ce107-3156-4420-8a2b-7f17efeaa472"
  }

  @doc """
  Generate a record
  """
  def record_fixture(attrs \\ %{}) do
    @record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  def collection_fixture(attrs \\ %{}) do
    collection =
      @collection_defaults
      |> Map.merge(attrs)
      |> Collection.create!()

    Records.load!(collection, [:records_to_export_query])
  end
end
