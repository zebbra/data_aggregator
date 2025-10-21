defmodule DataAggregator.ValidatedRecordTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationResponseFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord

  describe "validated_records" do
    @invalid_attrs %{
      record: nil,
      mte_catalog_number: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all validated_records" do
      collection = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})

      validated_record_one =
        validated_record_fixture(%{collection: collection}, %{
          mte_catalog_number: "validated_record1"
        })

      validated_record_two =
        validated_record_fixture(%{collection: collection}, %{
          mte_catalog_number: "validated_record2"
        })

      created = [
        validated_record_one,
        validated_record_two
      ]

      persisted = ValidatedRecord.read!(page: false, tenant: validated_record_one.collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the validated_record with given id" do
      created = validated_record_fixture()
      persisted = ValidatedRecord.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id, :collection_id])
    end

    test "create/1 with valid data creates a validated_record" do
      record = record_fixture()

      attrs = %{
        record: record,
        collection: record.collection
      }

      assert {:ok, %ValidatedRecord{} = result} =
               ValidatedRecord.create(attrs, tenant: record.collection)

      ValidatedRecord.create(attrs, tenant: record.collection)

      validated_record = Ash.load!(result, [:record])

      assert validated_record.record.id == record.id
      assert validated_record.collection.id == record.collection.id
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = ValidatedRecord.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the validated_record" do
      validated_record = validated_record_fixture()

      update_attrs = %{
        mte_catalog_number: "validated_record2",
        tax_scientific_name: "New Name"
      }

      assert {:ok, %ValidatedRecord{} = validated_record} =
               ValidatedRecord.update(validated_record, update_attrs)

      assert validated_record.mte_catalog_number == "validated_record2"
      assert validated_record.tax_scientific_name == "New Name"
    end

    test "update/2 with invalid data returns error changeset" do
      validated_record = validated_record_fixture()

      assert {:error, %Invalid{}} =
               ValidatedRecord.update(validated_record, @invalid_attrs)
    end

    test "destroy/1 deletes the validated_record" do
      validated_record = validated_record_fixture()
      assert :ok = ValidatedRecord.destroy(validated_record)

      assert_raise Invalid, fn ->
        ValidatedRecord.get_by_id!(validated_record.id, tenant: validated_record.collection)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} =
               ValidatedRecord.destroy(%ValidatedRecord{id: "invalid"})
    end
  end
end
