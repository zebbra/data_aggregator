defmodule DataAggregator.ValidationResponseTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationResponseFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationResponse

  require Logger

  describe "validation responses" do
    @invalid_attrs %{
      file_url: nil,
      type: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all validation responses" do
      created = [
        validation_response_fixture(),
        validation_response_fixture()
      ]

      persisted = ValidationResponse.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the validation response with given id" do
      created = validation_response_fixture()

      persisted = ValidationResponse.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = ValidationResponse.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the validation resopnse" do
      validation_response = validation_response_fixture()

      update_attrs = %{
        file_url: "test/support/fixtures/files/NEW-validation_dwca.zip"
      }

      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.update(validation_response, update_attrs)

      assert validation_response.file_url == "test/support/fixtures/files/NEW-validation_dwca.zip"
    end

    test "update/2 with invalid data returns error changeset" do
      validation_response = validation_response_fixture()

      assert {:error, %Invalid{}} =
               ValidationResponse.update(validation_response, @invalid_attrs)
    end

    test "add_affected_collection/1 adds the collections" do
      validation_response = validation_response_fixture()

      collection1 = collection_fixture(%{grscicoll_reference: "12345"})
      collection2 = collection_fixture(%{grscicoll_reference: "23456"})
      collection3 = collection_fixture(%{grscicoll_reference: "34567"})

      # Ensure an affected_collection is added
      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection1)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # Ensure further collections become part of the affected_collections list and do not replace existing ones
      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection2)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection2],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection3)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection2, collection3],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # Ensure duplicate additions do not change the affected_collections list
      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection3)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection2, collection3],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # TODO: more tests here...i.e. deletes.... implement this in the validation_response import process
    end

    test "destroy/1 deletes the validation response" do
      validation_response = validation_response_fixture()

      assert :ok = ValidationResponse.destroy(validation_response)

      assert_raise Invalid, fn ->
        ValidationResponse.get_by_id!(validation_response.id)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = ValidationResponse.destroy(%ValidationResponse{id: "invalid"})
    end
  end
end
