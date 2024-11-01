defmodule DataAggregator.Records.Import.Workers.ImporterTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Workers.Importer
  alias DataAggregator.Records.Record

  describe "DataAggregator.Records.Import.Workers.Importer.perform/1" do
    @valid_mapping [
      %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
      %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"}
    ]

    @invalid_mapping [
      %{name: "Scientific Name", mapped_to: "invalid_attribute"}
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
        |> Import.create_from_path!(path, tenant: collection)
        |> Import.update_mapping!(@valid_mapping)

      [import: import]
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "succeeds with a valid file", %{import: import} do
      {:ok, import} = perform_job(Importer, %{id: import.id, collection_id: import.collection_id})

      assert import.state == :imported
      assert import.records_count == 2
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "updates records_count upon import or records.destroy", %{
      collection: collection,
      import: import
    } do
      assert collection.records_count == 0

      {:ok, import} = perform_job(Importer, %{id: import.id, collection_id: import.collection_id})

      assert import.state == :imported
      assert import.records_count == 2

      collection = Collection.get_by_id!(collection.id)
      assert collection.records_count == 2

      [record | _] = Record.by_collection!(collection.id)
      Record.destroy(record)

      collection = Collection.get_by_id!(collection.id)
      assert collection.records_count == 1
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example-xs.csv"
    test "fails with invalid mapping", %{import: import} do
      import = Import.update_mapping!(import, @invalid_mapping)

      {result, logs} =
        with_log(fn ->
          perform_job(Importer, %{id: import.id, collection_id: import.collection_id})
        end)

      assert {:ok, import} = result
      assert import.state == :failed
      assert import.records_count == 0

      assert logs =~ "Found 1/1 invalid rows"
    end
  end
end
