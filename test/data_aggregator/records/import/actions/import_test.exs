defmodule DataAggregator.Records.Import.Actions.ImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  @valid_mapping [
    %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
    %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"},
    %{name: "event_date", mapped_to: "eve_event_date"}
  ]

  setup do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

    collection =
      %{
        type: :zoology,
        name: "Test Collection",
        owner: "Max Powers",
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      }
      |> Collection.create!()
      |> Collection.set_importing!()

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
    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs-encoding.csv"
    test "succeeds with a valid file", %{import: import} do
      assert import.rows_count == 18

      import = Import.import!(import)

      assert import.state == :imported
      assert import.records_count == 18
      assert import.started_at != nil
      assert import.finished_at != nil
      assert import.rows_valid_count == 18
      assert import.rows_invalid_count == 0
      assert import.rows_imported_count == 18

      assert record = hd(Record.read!())
      assert record.eve_event_date != nil
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs-encoding.csv"
    test "updates collections.records_count after import", %{
      collection: collection,
      import: import
    } do
      assert collection.records_count == 0

      Import.import!(import)

      collection = Collection.get_by_id!(collection.id)
      assert collection.records_count == 18
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
    @tag capture_log: true
    test "cannot be run multiple times", %{import: import} do
      assert {:ok, import} = Import.import(import)
      assert import.state == :imported
      assert import.records_count == 2
      assert import.rows_imported_count == 2
      assert import.rows_invalid_count == 0

      # Run again, which should not import the records again and throw an error
      assert {:error, %Ash.Error.Invalid{}} = Import.import(import)
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

    @tag path: "test/support/fixtures/files/duplicated_key_constraint_import.csv"
    test "detects duplicated key constrainst and adds error to import", %{import: import} do
      custom_mapping = [
        %{name: "verbatimIdentification", mapped_to: "tax_scientific_name"},
        %{name: "catalogNumber", mapped_to: "mte_catalog_number"}
      ]

      import = Import.update_mapping!(import, custom_mapping)

      assert {result, logs} = with_log(fn -> Import.import(import) end)
      assert {:ok, import} = result

      assert logs =~ "Found 1/2 invalid rows. Adding error to changeset"

      assert logs =~
               "1 errors occured while importing. Adding errors as file to `import.error_log`"

      assert import.state == :failed
      assert import.records_count == 0
      assert import.rows_imported_count == 0
      assert import.rows_invalid_count == 0
    end

    @tag path: "test/support/fixtures/files/invalid-format.csv"
    test "imports columns with invalid row format and still adds indicative error to import", %{
      import: import
    } do
      custom_mapping = [
        %{name: "verbatimIdentification", mapped_to: "tax_scientific_name"},
        %{name: "catalogNumber", mapped_to: "mte_catalog_number"}
      ]

      import = Import.update_mapping!(import, custom_mapping)

      assert {result, logs} = with_log(fn -> Import.import(import) end)
      assert {:ok, import} = result

      assert logs =~ "Found 1/1 invalid rows. Adding error to changeset"

      assert logs =~
               "2 errors occured while importing. Adding errors as file to `import.error_log`"

      assert import.state == :failed
      assert import.records_count == 0
      assert import.rows_imported_count == 0
      assert import.rows_invalid_count == 0
    end
  end
end
