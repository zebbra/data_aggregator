defmodule DataAggregator.Records.Import.Actions.ImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @valid_mapping [
    %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
    %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"}
  ]

  setup do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

    collection =
      Collection.create!(%{
        type: :zoology,
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

    [import: import, path: path]
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

    @tag path: "test/support/fixtures/files/invalid-records-small.csv"
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

    @tag path: "test/support/fixtures/files/invalid-records-huge.csv"
    test "fails with a file with huge amount of invalid records", %{import: import} do
      custom_mapping = [
        %{name: "original_taxon_name", mapped_to: "tax_scientific_name"},
        %{name: "barcode", mapped_to: "mte_catalog_number"},
        %{name: "latitude_dd", mapped_to: "loc_decimal_latitude"},
        %{name: "longitude_dd", mapped_to: "loc_decimal_longitude"}
      ]

      import = Import.update_mapping!(import, custom_mapping)

      assert {result, logs} = with_log(fn -> Import.import(import) end)

      assert {:ok, import} = result

      assert logs =~ "Found 1161/1161 invalid rows. Adding error to changeset"

      assert logs =~
               "1548 errors occured while importing. Adding errors as file to `import.error_log`"

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

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "imports columns with same order as provided by the import file", %{
      import: import,
      path: path
    } do
      assert {:ok, import} = Import.import(import)

      column_names = Enum.map(import.columns, & &1.name)
      column_order = DataAggregator.Records.Import.Changes.DetectColumns.column_order(path)

      assert column_names == column_order
    end
  end
end
