defmodule DataAggregator.ExportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Records.Collection

  import DataAggregator.PublicationFixtures
  import DataAggregator.RecordsFixtures

  describe "export crud tests" do
    @invalid_attrs %{
      name: nil
    }

    test "read!/0 returns all exports" do
      created = [
        export_fixture(),
        export_fixture()
      ]

      persisted = Export.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the export with given id" do
      created = export_fixture()
      persisted = Export.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 creates a export with valid data" do
      assert export_fixture()
    end

    test "create/1 with invalid data returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Export.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the export" do
      export = export_fixture()

      updated_export = %{
        name: "gbif.org_2",
        consumer: consumer_fixture(),
        records: [
          record_fixture(),
          record_fixture()
        ]
      }

      assert {:ok, %Export{} = export} =
               export
               |> Export.update(updated_export)
               |> DataAggregator.Platform.load([:consumer, :records_count])

      assert export.records_count == 2
      assert export.name == "gbif.org_2"
    end

    test "update/2 with invalid data fails and returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} =
               export_fixture() |> Export.update(@invalid_attrs)
    end

    test "destroy/1 deletes a export" do
      export = export_fixture()
      assert :ok = Export.destroy(export)
      assert_raise Ash.Error.Query.NotFound, fn -> Export.get_by_id!(export.id) end
    end

    test "destroy/1 with invalid id fails and returns an error changeset" do
      assert {:error, %Ash.Error.Unknown{}} = Export.destroy(%Export{id: "invalid"})
    end
  end

  setup do
    {:ok, collection} =
      Collection.create(%{name: "Collection for Publication", owner: "David Attenborough"})

    %{collection: collection}
  end

  describe "publication" do
    setup do
      records = [
        record_fixture(),
        record_fixture(),
        record_fixture(),
        record_fixture(),
        record_fixture()
      ]

      consumer = consumer_fixture()

      [records: records, consumer: consumer]
    end

    @tag run: true
    test "publish records for export", %{records: _records, consumer: _consumer} do
      {:ok, _result} = export_fixture() |> Export.publish()
    end
  end
end
