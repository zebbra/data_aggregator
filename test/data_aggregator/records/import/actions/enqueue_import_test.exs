defmodule DataAggregator.Records.Import.Actions.EnqueueImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  describe "DataAggregator.Records.Import.enqueue/1" do
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
      mapping = [
        %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
        %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"}
      ]

      import =
        collection
        |> Import.create_from_path!(path)
        |> Import.update_mapping!(mapping)

      [import: import]
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "enqueues a runner job", %{import: import} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, import} = Import.enqueue_import(import)

        assert import.state == :import_queued
        assert import.job != nil

        assert_enqueued(worker: Import.Workers.Importer, args: %{id: import.id})
      end)
    end
  end
end
