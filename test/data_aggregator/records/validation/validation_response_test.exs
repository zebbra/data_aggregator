defmodule DataAggregator.ValidationResponseTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ValidationFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Validation
  alias DataAggregator.RecordsFixtures

  require Logger

  describe "validations" do
    @invalid_attrs %{
      file_url: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all validations" do
      collection = RecordsFixtures.collection_fixture()

      created = [
        validation_fixture(%{collection: collection}),
        validation_fixture(%{collection: collection})
      ]

      persisted = Validation.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the validation with given id" do
      created = validation_fixture()

      persisted = Validation.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id, :collection_id])
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = Validation.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the validation" do
      validation = validation_fixture()

      update_attrs = %{
        file_url: "test/support/fixtures/files/NEW-validation_dwca.zip"
      }

      assert {:ok, %Validation{} = validation} = Validation.update(validation, update_attrs)

      assert validation.file_url == "test/support/fixtures/files/NEW-validation_dwca.zip"
    end

    test "update/2 with invalid data returns error changeset" do
      validation = validation_fixture()

      assert {:error, %Invalid{}} =
               Validation.update(validation, @invalid_attrs)
    end

    test "destroy/1 deletes the validation" do
      validation = validation_fixture()
      assert :ok = Validation.destroy(validation, tenant: validation.collection)

      assert_raise Invalid, fn ->
        Validation.get_by_id!(validation.id, tenant: validation.collection)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = Validation.destroy(%Validation{id: "invalid"})
    end
  end
end
