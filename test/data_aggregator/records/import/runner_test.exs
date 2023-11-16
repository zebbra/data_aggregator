defmodule DataAggregator.Records.Import.RunnerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Runner

  describe "DataAggregator.Records.Import.Runner.perform/1" do
    @valid_mapping [
      %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
      %{name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"}
    ]

    @invalid_mapping [
      %{name: "Scientific Name", mapped_to: "invalid_attribute"}
    ]

    setup do
      collection = Collection.create!(%{name: "Test Collection", owner: "Max Powers"})
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
      {:ok, import} = perform_job(Runner, %{id: import.id})

      assert import.state == :imported
      assert import.records_count == 2
      assert import.imported_at != nil
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "fails with invalid mapping", %{import: import} do
      import = Import.update_mapping!(import, @invalid_mapping)

      {result, logs} = with_log(fn -> perform_job(Runner, %{id: import.id}) end)

      assert {:ok, import} = result
      assert import.state == :failed
      assert import.records_count == 0
      assert import.imported_at == nil

      assert logs =~ "Imported 0/1 records (1 failed)"
      assert logs =~ "Error importing record:"
    end
  end
end
