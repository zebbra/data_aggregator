defmodule DataAggregator.Records.Import.Actions.ImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @valid_mapping [
    %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
    %{name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"}
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

  describe "DataAggregator.Records.Import.import/1" do
    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "succeeds with a valid file", %{import: import} do
      assert import.rows_count == 2

      import = Import.import!(import)

      assert import.state == :imported
      assert import.records_count == 2
      assert import.started_at != nil
      assert import.finished_at != nil
      assert import.rows_valid_count == 2
      assert import.rows_invalid_count == 0
      assert import.rows_imported_count == 2
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-invalid.csv"
    test "fails with a file with some invalid records", %{import: import} do
      {result, _logs} = with_log(fn -> Import.import(import) end)
      assert {:ok, import} = result

      assert import.state == :failed
      assert import.records_count == 0
      assert import.started_at != nil
      assert import.finished_at != nil
      assert import.rows_valid_count == 0
      assert import.rows_invalid_count == 0
      assert import.rows_imported_count == 0
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "can be run multiple times", %{import: import} do
      assert {:ok, import} = Import.import(import)
      assert import.state == :imported
      assert import.records_count == 2
      assert import.rows_imported_count == 2
      assert import.rows_invalid_count == 0

      # Run again, which should should not import the records again
      assert {:ok, import} = Import.import(import)
      assert import.state == :imported
      assert import.records_count == 2
      assert import.rows_imported_count == 2
      assert import.rows_invalid_count == 0
    end
  end
end
