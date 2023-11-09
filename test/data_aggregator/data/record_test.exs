defmodule DataAggregator.RecordsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Data.Record

  import DataAggregator.RecordsFixtures

  describe "records" do
    @invalid_attrs %{
      mte_material_entity_id: nil,
      tax_scientific_name: nil
    }

    test "read!/0 returns all records" do
      record = record_fixture()
      records = Record.read!(page: false)

      assert_maps(records, [%{id: record.id}])
    end

    test "get_by_id!/1 returns the record with given id" do
      record = record_fixture()

      record.id
      |> Record.get_by_id!()
      |> assert_map(%{id: record.id})
    end

    test "create/1 with valid data creates a record" do
      attrs = %{
        mte_material_entity_id: "record1",
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083",
        collection: collection_fixture()
      }

      assert {:ok, %Record{} = _record} = Record.create(attrs)
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Record.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the record" do
      record = record_fixture()

      update_attrs = %{
        mte_material_entity_id: "record2",
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
      }

      assert {:ok, %Record{} = _record} = Record.update(record, update_attrs)
    end

    test "update/2 with invalid data returns error changeset" do
      record = record_fixture()
      assert {:error, %Ash.Error.Invalid{}} = Record.update(record, @invalid_attrs)
    end

    test "destroy/1 deletes the record" do
      record = record_fixture()
      assert :ok = Record.destroy(record)
      assert_raise Ash.Error.Query.NotFound, fn -> Record.get_by_id!(record.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Unknown{}} = Record.destroy(%Record{id: "invalid"})
    end
  end

  describe "import action" do
    alias DataAggregator.Platform.Collection
    alias DataAggregator.Platform.Import

    setup do
      collection = Collection.create!(%{name: "My Collection", owner: "Max Powers"})
      [collection: collection]
    end

    setup %{collection: collection} do
      import = Import.create!(collection)
      [import: import]
    end

    test "importing a record", %{import: import} do
      params = %{
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Example",
        some_extra_data: "Extra"
      }

      assert {:ok, record} = Record.import(import, params)

      assert_maps(record.imports, [
        %{id: import.id}
      ])

      assert_map(record, %{
        collection_id: import.collection_id,
        tax_scientific_name: "Example",
        mte_material_entity_id: "ex-123",
        extra_data: %{
          "some_extra_data" => "Extra"
        },
        import_data: %{
          "mte_material_entity_id" => "ex-123",
          "tax_scientific_name" => "Example",
          "some_extra_data" => "Extra"
        }
      })
    end

    test "updating a record for the same import", %{import: import} do
      params = %{
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Example",
        some_extra_data: "Extra"
      }

      assert {:ok, record} = Record.import(import, params)

      updated_params = %{
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Updated Example",
        some_other_extra_data: "Other Extra"
      }

      assert {:ok, updated_record} = Record.import(import, updated_params)

      assert_maps(updated_record.imports, [
        %{id: import.id}
      ])

      assert_map(updated_record, %{
        id: record.id,
        collection_id: import.collection_id,
        tax_scientific_name: "Updated Example",
        mte_material_entity_id: "ex-123",
        extra_data: %{
          "some_other_extra_data" => "Other Extra"
        }
      })
    end

    test "updating a record from another import", %{import: import} do
      params = %{
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Example",
        some_extra_data: "Extra"
      }

      assert {:ok, record} = Record.import(import, params)

      updated_params = %{
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Updated Example",
        some_other_extra_data: "Other Extra"
      }

      other_import = Import.create!(record.collection)

      assert {:ok, updated_record} = Record.import(other_import, updated_params)

      assert_maps(updated_record.imports, [
        %{id: other_import.id},
        %{id: import.id}
      ])

      assert_map(updated_record, %{
        id: record.id,
        collection_id: record.collection_id,
        tax_scientific_name: "Updated Example",
        mte_material_entity_id: "ex-123",
        extra_data: %{
          "some_other_extra_data" => "Other Extra"
        }
      })
    end

    test "importing a record for another collection", %{import: import} do
      params = %{
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Example"
      }

      record = import |> Record.import!(params)

      other_collection = Collection.create!(%{name: "Another Collection", owner: "Max Powers"})
      other_import = Import.create!(other_collection)

      assert {:ok, other_record} = Record.import(other_import, params)

      refute record.id == other_record.id

      assert_map(other_record, %{
        collection_id: other_collection.id,
        mte_material_entity_id: "ex-123",
        tax_scientific_name: "Example"
      })
    end
  end
end
