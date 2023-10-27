defmodule DataAggregator.RecordsTest do
  use DataAggregator.DataCase

  describe "records" do
    alias DataAggregator.Data.Record

    import DataAggregator.RecordsFixtures

    @invalid_attrs %{materialEntityID: nil, scientificName: nil}
    @valid_attrs %{
      materialEntityID: "record1",
      scientificName: "06809dc5-f143-459a-be1a-6f03e63fc083"
    }

    test "read!/0 returns all records" do
      record = record_fixture()
      page = Record.read!()
      assert page.results == [record]
    end

    test "get_by_id!/1 returns the record with given id" do
      record = record_fixture()
      assert Record.get_by_id!(record.id) == record
    end

    test "create/1 with valid data creates a record" do
      assert {:ok, %Record{} = _record} = Record.create(@valid_attrs)
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Record.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the record" do
      record = record_fixture()

      update_attrs = %{
        materialEntityID: "record2",
        scientificName: "06809dc5-f143-459a-be1a-6f03e63fc083"
      }

      assert {:ok, %Record{} = _record} =
               Record.update(record, update_attrs)
    end

    test "update/2 with invalid data returns error changeset" do
      record = record_fixture()
      assert {:error, %Ash.Error.Invalid{}} = Record.update(record, @invalid_attrs)
      assert record == Record.get_by_id!(record.id)
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
end
