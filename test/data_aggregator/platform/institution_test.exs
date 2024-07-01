defmodule DataAggregator.InstitutionTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.PlatformFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Platform.Institution

  describe "institutions" do
    @invalid_attrs %{
      name: nil,
      grscicoll_reference: "5b487a79-76ef-4615-93d9-f4ea25a40c33"
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all institutions" do
      created = [
        institution_fixture(),
        institution_fixture()
      ]

      persisted = Institution.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the institution with given id" do
      created = institution_fixture()
      persisted = Institution.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with valid data creates a institution" do
      attrs = %{
        name: "Institution A",
        grscicoll_reference: "5b487a79-76ef-4615-93d9-f4ea25a40c33"
      }

      assert {:ok, %Institution{} = _institution} = Institution.create(attrs)
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Institution.create(@invalid_attrs)
    end

    test "create/1 with missing :grscicoll_reference data returns error changeset" do
      attrs = Map.delete(@invalid_attrs, :grscicoll_reference)

      assert {:error, %Ash.Error.Invalid{}} = Institution.create(attrs)
    end

    test "create/1 with ivalid :grscicoll_reference data returns error changeset" do
      attrs =
        Map.put(@invalid_attrs, :grscicoll_reference, "this-is-super-wrong")

      assert {:error, %Ash.Error.Invalid{}} = Institution.create(attrs)
    end

    test "update/2 with valid data updates the institution" do
      institution = institution_fixture()

      update_attrs = %{
        name: "Institution B"
      }

      assert {:ok, %Institution{} = _institution} = Institution.update(institution, update_attrs)
    end

    test "update/2 with invalid data returns error changeset" do
      institution = institution_fixture()
      assert {:error, %Ash.Error.Invalid{}} = Institution.update(institution, @invalid_attrs)
    end

    test "destroy/1 deletes the institution" do
      institution = institution_fixture()
      assert :ok = Institution.destroy(institution)
      assert_raise Ash.Error.Query.NotFound, fn -> Institution.get_by_id!(institution.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Invalid{}} = Institution.destroy(%Institution{id: "invalid"})
    end
  end
end
