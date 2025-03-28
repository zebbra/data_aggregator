defmodule DataAggregator.CollectionTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection

  describe "collections" do
    @invalid_attrs %{
      name: nil,
      owner: "Max Powers",
      type: :invalid,
      grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all collections" do
      created = [
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()}),
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      ]

      persisted = Collection.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the collection with given id" do
      created = collection_fixture()
      persisted = Collection.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with valid data creates a collection" do
      attrs = %{
        name: "Collection",
        owner: "Max Powers",
        type: :zoology,
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      }

      assert {:ok, %Collection{} = collection} = Collection.create(attrs)

      assert collection.grscicoll_institution_key === "5b487a79-76ef-4615-93d9-f4ea25a40c33"
      assert collection.grscicoll_institution_code === "Z"
      assert collection.grscicoll_institution_name === "Universität Zürich"
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = Collection.create(@invalid_attrs)
    end

    test "create/1 with missing :grscicoll_reference data returns error changeset" do
      attrs = Map.delete(@invalid_attrs, :grscicoll_reference)

      assert {:error, %Invalid{}} = Collection.create(attrs)
    end

    test "create/1 with ivalid :grscicoll_reference data returns error changeset" do
      attrs = Map.put(@invalid_attrs, :grscicoll_reference, "this-is-super-wrong")

      assert {:error, %Invalid{}} = Collection.create(attrs)
    end

    test "update/2 with valid data updates the collection" do
      collection = collection_fixture()

      update_attrs = %{
        name: "Collection 2",
        owner: "Max Powers 2",
        type: :botany
      }

      assert {:ok, %Collection{} = _collection} = Collection.update(collection, update_attrs)
    end

    test "update_import_mapping/2 with valid column mapping data updates the collection" do
      collection = collection_fixture()

      updated_import_mapping = [
        %{"name" => "Scientific Name", "mapped_to" => "tax_scientific_name"},
        %{"name" => "Numéro scientifique GBIF", "mapped_to" => "mte_catalog_number"}
      ]

      assert {:ok, %Collection{} = result} =
               Collection.update_import_mapping(collection, updated_import_mapping)

      assert result.import_mapping == updated_import_mapping
    end

    test "update/2 with invalid data returns error changeset" do
      collection = collection_fixture()
      assert {:error, %Invalid{}} = Collection.update(collection, @invalid_attrs)
    end

    test "destroy/1 deletes the collection" do
      collection = collection_fixture()
      assert :ok = Collection.destroy(collection)
      assert_raise Ash.Error.Invalid, fn -> Collection.get_by_id!(collection.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = Collection.destroy(%Collection{id: "invalid"})
    end
  end
end
