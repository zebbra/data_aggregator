defmodule DataAggregator.Records.Import.Calculations.MappingsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @path "test/support/fixtures/files/museum-dataset-import-example-xs.csv"

  setup do
    {:ok, collection} =
      Collection.create(%{
        name: "Test Collection",
        owner: "Max Powers",
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      })

    %{collection: collection}
  end

  setup %{collection: collection} do
    import =
      Import.create_from_path!(collection, @path)

    %{import: import}
  end

  test "with missing mappings", %{import: import} do
    {:ok, import} = Records.load(import, :mappings, lazy?: true)

    expected = [
      {nil, "mte_catalog_number"},
      {nil, "tax_scientific_name"}
    ]

    assert_mappings(import, expected)
  end

  test "with all mandatory attributes mapped", %{import: import} do
    {:ok, import} = Records.load(import, :mappings, lazy?: true)

    import =
      Import.update_mapping!(import, [
        %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"},
        %{name: "Scientific Name", mapped_to: "tax_scientific_name"}
      ])

    expected = [
      {"Numéro scientifique GBIF", "mte_catalog_number"},
      {"Scientific Name", "tax_scientific_name"}
    ]

    assert_mappings(import, expected)
  end

  defp assert_mappings(import, expected) do
    import.mappings
    |> Enum.map(&{&1.name, &1.mapped_to})
    |> assert_lists_equal(expected)
  end
end
