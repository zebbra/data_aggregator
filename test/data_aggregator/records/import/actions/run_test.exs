defmodule DataAggregator.Records.Import.Actions.RunTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  # @tag :focus
  describe "DataAggregator.Records.Import.run/1" do
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

    @tag :focus
    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "succeeds with a valid file", %{import: import} do
      {:ok, import} = Import.run(import)

      assert import.state == :imported
      assert import.records_count == 2
      assert import.imported_at != nil
      assert import.finished_at != nil
      assert import.imported_count == 2
      assert import.invalid_count == 0
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-invalid.csv"
    test "succeeds with a file with some invalid records", %{import: import} do
      {result, logs} = with_log(fn -> Import.run(import) end)

      assert {:ok, import} = result

      assert import.state == :imported
      assert import.records_count == 6
      assert import.finished_at != nil
      assert import.imported_count == 6
      assert import.invalid_count == 1

      assert logs =~ "1 invalid row(s) dropped from chunk!"
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "can be run multiple times", %{import: import} do
      # Run once with invalid mapping
      import = Import.update_mapping!(import, @invalid_mapping)
      {result, _logs} = with_log(fn -> Import.run(import) end)

      assert {:ok, import} = result
      assert import.state == :failed
      assert import.records_count == 0
      assert import.imported_at == nil
      assert import.imported_count == nil
      assert import.invalid_count == nil

      # Run again with valid mapping
      import = Import.update_mapping!(import, @valid_mapping)

      assert {:ok, import} = Import.run(import)
      assert import.state == :imported
      assert import.records_count == 2
      assert import.imported_at != nil
      assert import.imported_count == 2
      assert import.invalid_count == 0

      # Run again, which should should not import the records again
      assert {:ok, import} = Import.run(import)
      assert import.state == :imported
      assert import.records_count == 2
      assert import.imported_at != nil
      assert import.imported_count == 2
      assert import.invalid_count == 0
    end
  end
end
