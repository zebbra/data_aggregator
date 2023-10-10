defmodule DataAggregator.ImportsTest do
  use DataAggregator.DataCase

  describe "imports" do
    alias DataAggregator.Imports.Import

    import DataAggregator.ImportsFixtures

    @invalid_attrs %{name: nil}
    @valid_attrs %{name: "import1", version: 1, collection_id: "496752bc-6743-11ee-8c99-0242ac120002"}

    test "read!/0 returns all imports" do
      import = import_fixture()
      assert Import.read!() == [import]
    end

    test "get_by_id!/1 returns the import with given id" do
      import = import_fixture()
      assert Import.get_by_id!(import.id) == import
    end

    test "create/1 with valid data creates a import" do
      assert {:ok, %Import{} = _import} = Import.create(@valid_attrs)
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Import.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the import" do
      import = import_fixture()
      update_attrs = %{name: "import2"}

      assert {:ok, %Import{} = _import} = Import.update(import, update_attrs)
    end

    test "update/2 with invalid data returns error changeset" do
      import = import_fixture()
      assert {:error, %Ash.Error.Invalid{}} = Import.update(import, @invalid_attrs)
      assert import == Import.get_by_id!(import.id)
    end

    test "destroy/1 deletes the import" do
      import = import_fixture()
      assert :ok = Import.destroy(import)
      assert_raise Ash.Error.Query.NotFound, fn -> Import.get_by_id!(import.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Unknown{}} = Import.destroy(%Import{id: "invalid"})
    end
  end
end
