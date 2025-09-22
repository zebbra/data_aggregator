defmodule DataAggregator.ValidationResponseTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationResponseFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponseCollection

  require Logger

  describe "validation responses" do
    @invalid_attrs %{
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

      # check if the through table of the many-to-many relationship is updated correctly
      assert {:ok, vr_2_colls} = Ash.read(ValidationResponseCollection)
      assert length(vr_2_colls) == 1

      # check if :validation_responses on collections are updated correctly
      assert {:ok, collection} =
               collection1.id |> Collection.get_by_id() |> Ash.load([:validation_responses])

      assert_lists_equal(
        collection.validation_responses,
        [validation_response],
        &assert_structs_equal(&1, &2, [:id])
      )

      # Ensure further collections become part of the affected_collections list and do not replace existing ones
      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection2)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection2],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # check if the through table of the many-to-many relationship is updated correctly
      assert {:ok, vr_2_colls} = Ash.read(ValidationResponseCollection)
      assert length(vr_2_colls) == 2

      # check if :validation_responses on collections are updated correctly
      assert {:ok, collection} = Ash.load(collection1, [:validation_responses])

      assert_lists_equal(
        collection.validation_responses,
        [validation_response],
        &assert_structs_equal(&1, &2, [:id])
      )

      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection3)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection2, collection3],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # check if the through table of the many-to-many relationship is updated correctly
      assert {:ok, vr_2_colls} = Ash.read(ValidationResponseCollection)
      assert length(vr_2_colls) == 3

      # check if :validation_responses on collections are updated correctly
      assert {:ok, collection} = Ash.load(collection1, [:validation_responses])

      assert_lists_equal(
        collection.validation_responses,
        [validation_response],
        &assert_structs_equal(&1, &2, [:id])
      )

      # Ensure duplicate additions do not change the affected_collections list
      assert {:ok, %ValidationResponse{} = validation_response} =
               ValidationResponse.add_affected_collection(validation_response, collection3)

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection2, collection3],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # check if the through table of the many-to-many relationship is updated correctly
      assert {:ok, vr_2_colls} = Ash.read(ValidationResponseCollection)
      assert length(vr_2_colls) == 3

      # check if :validation_responses on collections are updated correctly
      assert {:ok, collection} = Ash.load(collection1, [:validation_responses])

      assert_lists_equal(
        collection.validation_responses,
        [validation_response],
        &assert_structs_equal(&1, &2, [:id])
      )

      # check if deletions of collections are handled correctly
      assert :ok = Collection.destroy(collection2)
      assert {:ok, validation_response} = Ash.load(validation_response, [:affected_collections])

      assert_lists_equal(
        validation_response.affected_collections,
        [collection1, collection3],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      # check if deletions of validation responses are handled correctly
      assert(:ok = ValidationResponse.destroy(validation_response))

      assert {:ok, collection} = Ash.load(collection1, [:validation_responses])

      assert collection.validation_responses == []
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
