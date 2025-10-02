defmodule DataAggregator.EncodedRecordTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord

  describe "encoded_records" do
    @invalid_attrs %{
      record: nil,
      mte_catalog_number: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all encoded_records" do
      collection = collection_fixture()

      created = [
        encoded_record_fixture(%{
          record: record_fixture(%{collection: collection, mte_catalog_number: "record1"})
        }),
        encoded_record_fixture(%{
          record: record_fixture(%{collection: collection, mte_catalog_number: "record2"})
        })
      ]

      persisted = EncodedRecord.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the encoded_record with given id" do
      created = encoded_record_fixture()
      persisted = EncodedRecord.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with valid data creates a encoded_record" do
      record = record_fixture()

      attrs = %{record: record}

      assert {:ok, %EncodedRecord{} = result} =
               EncodedRecord.create(attrs, tenant: record.collection)

      encoded_record = Ash.load!(result, [:record], tenant: record.collection)

      assert encoded_record.record.id == record.id
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = EncodedRecord.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the encoded_record" do
      encoded_record = encoded_record_fixture()

      update_attrs = %{
        mte_catalog_number: "encoded_record2",
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
      }

      assert {:ok, %EncodedRecord{} = encoded_record} =
               EncodedRecord.update(encoded_record, update_attrs)

      assert EncodedRecord.get_by_id!(encoded_record.id, tenant: encoded_record.collection).mte_catalog_number ==
               "encoded_record2"
    end

    test "update/2 with invalid data returns error changeset" do
      encoded_record = encoded_record_fixture()
      assert {:error, %Invalid{}} = EncodedRecord.update(encoded_record, @invalid_attrs)
    end

    test "destroy/1 deletes the encoded_record" do
      encoded_record = encoded_record_fixture()
      assert :ok = EncodedRecord.destroy(encoded_record)

      assert_raise Ash.Error.Invalid, fn ->
        EncodedRecord.get_by_id!(encoded_record.id, tenant: encoded_record.collection)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = EncodedRecord.destroy(%EncodedRecord{id: "invalid"})
    end

    test "update_return_minimal_fields/1 returns only minimal data" do
      original_encoded_record =
        encoded_record_fixture(%{tax_family: "Oenantheae", tax_kingdom: "Plantae"})

      encoded_record =
        EncodedRecord.update_return_minimal_fields!(original_encoded_record, %{
          tax_family: "new family"
        })

      assert encoded_record != nil

      # according to Encoding.Changes.SelectMinimalFields --> nsure correct attributes are present and loaded...
      assert encoded_record.id == original_encoded_record.id
      assert encoded_record.record_id == original_encoded_record.record_id
      assert encoded_record.collection_id == original_encoded_record.collection_id
      assert encoded_record.mte_catalog_number == original_encoded_record.mte_catalog_number
      assert encoded_record.tax_scientific_name == original_encoded_record.tax_scientific_name

      # ...and not explicitly loaded attributes are not loaded
      assert encoded_record.tax_family == %Ash.NotLoaded{
               type: :attribute,
               field: :tax_family
             }

      # then reload the record to ensure the updated values are loaded
      encoded_record = Ash.reload!(encoded_record)

      assert encoded_record.tax_family == "new family"
    end
  end
end
