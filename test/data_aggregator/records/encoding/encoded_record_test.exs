defmodule DataAggregator.EncodedRecordTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord

  describe "encoded_records" do
    @invalid_attrs %{
      record: nil,
      mte_material_entity_id: nil
    }

    test "read!/0 returns all encoded_records" do
      created = [
        encoded_record_fixture(),
        encoded_record_fixture()
      ]

      persisted = EncodedRecord.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the encoded_record with given id" do
      created = encoded_record_fixture()
      persisted = EncodedRecord.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with valid data creates a encoded_record" do
      record = record_fixture()

      attrs = %{
        record: record
      }

      assert {:ok, %EncodedRecord{} = result} = EncodedRecord.create(attrs)

      encoded_record = Records.load!(result, [:record])

      assert encoded_record.record.id == record.id
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = EncodedRecord.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the encoded_record" do
      encoded_record = encoded_record_fixture()

      update_attrs = %{
        mte_material_entity_id: "encoded_record2",
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
      }

      assert {:ok, %EncodedRecord{} = encoded_record} =
               EncodedRecord.update(encoded_record, update_attrs)

      assert EncodedRecord.get_by_id!(encoded_record.id).mte_material_entity_id ==
               "encoded_record2"
    end

    test "update/2 with invalid data returns error changeset" do
      encoded_record = encoded_record_fixture()
      assert {:error, %Ash.Error.Invalid{}} = EncodedRecord.update(encoded_record, @invalid_attrs)
    end

    test "destroy/1 deletes the encoded_record" do
      encoded_record = encoded_record_fixture()
      assert :ok = EncodedRecord.destroy(encoded_record)
      assert_raise Ash.Error.Query.NotFound, fn -> EncodedRecord.get_by_id!(encoded_record.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Invalid{}} = EncodedRecord.destroy(%EncodedRecord{id: "invalid"})
    end
  end
end
