defmodule DataAggregator.Records.Import.Actions.EnqueueImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  describe "DataAggregator.Records.Import.enqueue_import/1" do
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
      mapping = [
        %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
        %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"}
      ]

      import =
        collection
        |> Import.create_from_path!(path)
        |> Import.update_mapping!(mapping)

      [collection: collection, import: import]
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

    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "enqueue_import/1 fails if collection is in state importing", %{
      collection: collection,
      import: import
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_importing!(collection)
        assert_not_enqueued(import)
      end)
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "enqueue_import/1 fails if collection is in state exporting", %{
      collection: collection,
      import: import
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_exporting!(collection)
        assert_not_enqueued(import)
      end)
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "enqueue_import/1 fails if collection is in state encoding", %{
      collection: collection,
      import: import
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_encoding!(collection)
        assert_not_enqueued(import)
      end)
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "enqueue_import/1 fails if collection is in state approving", %{
      collection: collection,
      import: import
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_approving!(collection)
        assert_not_enqueued(import)
      end)
    end

    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "enqueue_import/1 fails if collection is in state fast_track_publishing", %{
      collection: collection,
      import: import
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_fast_track_publishing!(collection)
        assert_not_enqueued(import)
      end)
    end

    defp assert_not_enqueued(import) do
      assert {:error, %Ash.Error.Invalid{}} = Import.enqueue_import(import)
      import = Import.get_by_id!(import.id)
      assert import.state == :pending
      refute_enqueued(worker: Import.Workers.Importer, args: %{id: import.id})
    end
  end
end
