defmodule DataAggregator.CollectionTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ExportFixtures
  import DataAggregator.ImageUploadFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationRequestRecordFixtures
  import DataAggregator.ValidationResponseFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequestRecord
  alias DataAggregator.Records.ValidationRequestRecord.Version, as: ValidationRequestRecordVersion
  alias DataAggregator.Records.ValidationResponse

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
      assert :ok = Collection.destroy(collection, tenant: collection)
      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end
    end

    test "destroy/1 deletes the collection and cascades to imports" do
      collection = collection_fixture()

      import =
        Import.create_from_path!(
          collection,
          "test/support/fixtures/files/museum-dataset-import-example-xs.csv",
          tenant: collection
        )

      assert :ok = Collection.destroy(collection, tenant: collection)

      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end

      assert_raise Invalid, fn ->
        Import.get_by_id!(import.id, tenant: collection)
      end
    end

    test "destroy/1 deletes the collection and cascades to exports" do
      collection = collection_fixture()

      export = export_fixture(%{collection: collection})

      assert :ok = Collection.destroy(collection, tenant: collection)

      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end
      assert_raise Invalid, fn -> Export.get_by_id!(export.id, tenant: collection) end
    end

    test "destroy/1 deletes the collection and cascades to records" do
      collection = collection_fixture()

      record =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "test_record_123",
          tax_scientific_name: "Test species"
        })

      assert :ok = Collection.destroy(collection, tenant: collection)

      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end
      assert_raise Invalid, fn -> Record.get_by_id!(record.id, tenant: collection) end
    end

    test "destroy/1 deletes the collection and cascades to image uploads" do
      collection = collection_fixture()

      image_upload = image_upload_fixture(collection)

      assert :ok = Collection.destroy(collection, tenant: collection)

      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end
      assert_raise Invalid, fn -> ImageUpload.get_by_id!(image_upload.id, tenant: collection) end
    end

    test "destroy/1 deletes the collection and cascades to validation responses" do
      collection = collection_fixture()

      validation_response = validation_response_fixture(%{type: :validated})

      ValidationResponse.add_affected_collection!(validation_response, collection)

      loaded_collection =
        collection.id |> Collection.get_by_id!() |> Ash.load!([:validation_responses])

      assert length(loaded_collection.validation_responses) == 1

      assert :ok = Collection.destroy(collection, tenant: collection)

      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end

      # The validation response itself should still exist (its not cascade deleted,
      # just disassociated because it could be used by other colections)
      assert ValidationResponse.get_by_id!(validation_response.id)
    end

    test "destroy/1 deletes collection with multiple related entities" do
      collection = collection_fixture()

      import =
        Import.create_from_path!(
          collection,
          "test/support/fixtures/files/museum-dataset-import-example-xs.csv",
          tenant: collection
        )

      export = export_fixture(%{collection: collection, name: "Multi Test Export"})

      record =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "multi_test_record_456",
          tax_scientific_name: "Multi test species"
        })

      validation_request_record =
        validation_request_record_fixture(%{collection: collection, record: record})

      publication =
        Publication.create!(
          %{
            name: "Publication 2",
            records_query: %{},
            collection: collection
          },
          tenant: collection
        )

      {:ok, publication} = Publication.run(publication)

      validation_request =
        ValidationRequest.create!(
          %{
            name: "Validation Request",
            center: :infofauna,
            records_query: %{},
            total_rows_count: 1,
            collection: collection
          },
          tenant: collection
        )

      {:ok, validation_request} = ValidationRequest.run(validation_request)

      image_upload = image_upload_fixture(collection)

      assert :ok = Collection.destroy(collection, tenant: collection)

      assert_raise Invalid, fn -> Collection.get_by_id!(collection.id) end
      assert_raise Invalid, fn -> Import.get_by_id!(import.id, tenant: collection) end
      assert_raise Invalid, fn -> Export.get_by_id!(export.id, tenant: collection) end
      assert_raise Invalid, fn -> Record.get_by_id!(record.id, tenant: collection) end
      assert_raise Invalid, fn -> ImageUpload.get_by_id!(image_upload.id, tenant: collection) end
      assert_raise Invalid, fn -> Publication.get_by_id!(publication.id, tenant: collection) end

      assert_raise Invalid, fn ->
        ValidationRequestRecord.get_by_id!(validation_request_record.id)
      end

      assert_raise Invalid, fn ->
        ValidationRequest.get_by_id!(validation_request.id)
      end

      assert_lists_equal([], ValidationRequestRecordVersion.read!(tenant: collection))

      assert {:ok, attachments} = Attachment.read()

      Enum.each(attachments, fn attachment ->
        assert attachment.deletable == true
      end)
    end

    test "destroy/1 with invalid id returns error" do
      collection = %Collection{id: "62809dc5-f143-459a-be1a-6f03e63fc044"}
      assert {:error, %Invalid{}} = Collection.destroy(collection, tenant: collection)
    end
  end
end
