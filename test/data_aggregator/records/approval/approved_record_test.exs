defmodule DataAggregator.ApprovedRecordTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.ApprovedRecord

  describe "approved_records" do
    @invalid_attrs %{
      record: nil,
      mte_catalog_number: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all approved_records" do
      collection = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})

      approved_record_one =
        approved_record_fixture(%{collection: collection}, %{
          mte_catalog_number: "approved_record1"
        })

      approved_record_two =
        approved_record_fixture(%{collection: collection}, %{
          mte_catalog_number: "approved_record2"
        })

      created = [
        approved_record_one,
        approved_record_two
      ]

      persisted = ApprovedRecord.read!(page: false, tenant: approved_record_one.collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the approved_record with given id" do
      created = approved_record_fixture()
      persisted = ApprovedRecord.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id, :collection_id])
    end

    test "create/1 with valid data creates a approved_record" do
      record = record_fixture()

      attrs = %{
        record: record,
        collection: record.collection
      }

      assert {:ok, %ApprovedRecord{} = result} =
               ApprovedRecord.create(attrs, tenant: record.collection)

      ApprovedRecord.create(attrs, tenant: record.collection)

      approved_record = Ash.load!(result, [:record])

      assert approved_record.record.id == record.id
      assert approved_record.collection.id == record.collection.id
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = ApprovedRecord.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the approved_record" do
      approved_record = approved_record_fixture()

      update_attrs = %{
        mte_catalog_number: "approved_record2",
        tax_scientific_name: "New Name"
      }

      assert {:ok, %ApprovedRecord{} = approved_record} =
               ApprovedRecord.update(approved_record, update_attrs)

      assert approved_record.mte_catalog_number == "approved_record2"
      assert approved_record.tax_scientific_name == "New Name"
    end

    test "update/2 with invalid data returns error changeset" do
      approved_record = approved_record_fixture()

      assert {:error, %Invalid{}} =
               ApprovedRecord.update(approved_record, @invalid_attrs)
    end

    test "destroy/1 deletes the approved_record" do
      approved_record = approved_record_fixture()
      assert :ok = ApprovedRecord.destroy(approved_record)

      assert_raise Ash.Error.Query.NotFound, fn ->
        ApprovedRecord.get_by_id!(approved_record.id, tenant: approved_record.collection)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} =
               ApprovedRecord.destroy(%ApprovedRecord{id: "invalid"})
    end
  end
end
