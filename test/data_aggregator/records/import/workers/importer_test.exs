defmodule DataAggregator.Records.Import.Workers.ImporterTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Workers.Importer

  describe "DataAggregator.Records.Import.Workers.Importer.perform/1" do
    @valid_mapping [
      %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
      %{name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"}
    ]

    @invalid_mapping [
      %{name: "Scientific Name", mapped_to: "invalid_attribute"}
    ]

    setup do
      collection =
        Collection.create!(%{
          name: "Test Collection",
          owner: "Max Powers",
          grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
        })

      [collection: collection]
    end

    setup %{collection: collection, path: path} do
      import =
        collection
        |> Import.create_from_path!(path)
        |> Import.update_mapping!(@valid_mapping)

      [import: import]
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "succeeds with a valid file", %{import: import} do
      {:ok, import} = perform_job(Importer, %{id: import.id})

      assert import.state == :imported
      assert import.records_count == 2
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "fails with invalid mapping", %{import: import} do
      import = Import.update_mapping!(import, @invalid_mapping)

      {result, logs} = with_log(fn -> perform_job(Importer, %{id: import.id}) end)

      assert {:ok, import} = result
      assert import.state == :failed
      assert import.records_count == 0

      assert logs =~ "Found 2/2 invalid rows"
    end
  end
end
