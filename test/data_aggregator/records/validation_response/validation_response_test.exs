defmodule DataAggregator.ValidationResponseTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ValidationResponseFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.RecordsFixtures

  require Logger

  describe "validation responses" do
    @invalid_attrs %{
      file_url: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all validation responses" do
      collection = RecordsFixtures.collection_fixture()

      created = [
        validation_response_fixture(%{collection: collection}),
        validation_response_fixture(%{collection: collection})
      ]

      persisted = ValidationResponse.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the validation response with given id" do
      created = validation_response_fixture()

      persisted = ValidationResponse.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id, :collection_id])
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

    test "destroy/1 deletes the validation response" do
      validation_response = validation_response_fixture()

      assert :ok =
               ValidationResponse.destroy(validation_response,
                 tenant: validation_response.collection
               )

      assert_raise Invalid, fn ->
        ValidationResponse.get_by_id!(validation_response.id,
          tenant: validation_response.collection
        )
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = ValidationResponse.destroy(%ValidationResponse{id: "invalid"})
    end
  end
end
