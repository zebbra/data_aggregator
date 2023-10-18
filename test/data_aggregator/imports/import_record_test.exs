defmodule DataAggregator.ImportRecordsTest do
  use DataAggregator.DataCase

  describe "import_records" do
    alias DataAggregator.Imports.ImportRecord

    import DataAggregator.ImportRecordsFixtures

    @invalid_attrs %{unique_qualifier: nil}
    @valid_attrs %{
      unique_qualifier: "import_record1"
    }

    test "read!/0 returns all import_records" do
      import_record = import_record_fixture()
      assert ImportRecord.read!() == [import_record]
    end

    test "get_by_id!/1 returns the import_record with given id" do
      import_record = import_record_fixture()
      assert ImportRecord.get_by_id!(import_record.id) == import_record
    end

    test "create/1 with valid data creates a import_record" do
      assert {:ok, %ImportRecord{} = _import_record} = ImportRecord.create(@valid_attrs)
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = ImportRecord.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the import_record" do
      import_record = import_record_fixture()
      update_attrs = %{unique_qualifier: "import_record2"}

      assert {:ok, %ImportRecord{} = _import_record} =
               ImportRecord.update(import_record, update_attrs)
    end

    test "update/2 with invalid data returns error changeset" do
      import_record = import_record_fixture()
      assert {:error, %Ash.Error.Invalid{}} = ImportRecord.update(import_record, @invalid_attrs)
      assert import_record == ImportRecord.get_by_id!(import_record.id)
    end

    test "destroy/1 deletes the import_record" do
      import_record = import_record_fixture()
      assert :ok = ImportRecord.destroy(import_record)
      assert_raise Ash.Error.Query.NotFound, fn -> ImportRecord.get_by_id!(import_record.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Unknown{}} = ImportRecord.destroy(%ImportRecord{id: "invalid"})
    end
  end
end
