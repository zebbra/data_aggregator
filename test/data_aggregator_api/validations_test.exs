defmodule DataAggregatorApi.ValidationsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Validation
  alias DataAggregator.ValidationFixtures
  alias DataAggregatorApi.HelpersTest

  setup %{conn: conn} do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
    stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

    stub(DataAggregator.Records.Validation.Changes.ValidateRecords, :change, fn changeset, _, _ ->
      changeset
    end)

    stub(DataAggregator.Records.Validation.Changes.SetCount, :change, fn changeset, _, _ ->
      changeset
    end)

    # Create a test user with admin role
    user =
      AccountsFixtures.user_fixture(%{
        email: "john.doe@example.com",
        password: "secret42",
        roles: ["admin", "collection_administrator", "data_digitizer"]
      })

    # Trade the user for a token
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

    # Add request headers
    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")
      |> put_req_header("authorization", token)

    # Create a test collection
    collection = HelpersTest.setup_collection()

    # Create validations
    validation_1 = ValidationFixtures.validation_fixture(%{collection: collection})
    validation_2 = ValidationFixtures.validation_fixture(%{collection: collection})
    validation_3 = ValidationFixtures.validation_fixture(%{collection: collection})

    {:ok,
     conn: conn,
     collection: collection,
     validation_1: validation_1,
     validation_2: validation_2,
     validation_3: validation_3}
  end

  describe "/api/json/datasets/:collection_id/validations" do
    test "lists all validations", %{
      conn: conn,
      collection: collection,
      validation_1: validation_1,
      validation_2: validation_2,
      validation_3: validation_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/validations", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] in [validation_1.id, validation_2.id, validation_3.id]
      assert Enum.at(data, 1)["id"] in [validation_1.id, validation_2.id, validation_3.id]
      assert Enum.at(data, 2)["id"] in [validation_1.id, validation_2.id, validation_3.id]
      assert Enum.at(data, 3) == nil
    end

    test "filters validations by file_url succeeded", %{
      conn: conn,
      collection: collection,
      validation_1: validation_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/validations?filter[file_url]=#{validation_1.file_url}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == validation_1.id

      assert Enum.at(data, 0)["attributes"]["file_url"] ==
               validation_1.file_url
    end

    test "get one validation", %{
      conn: conn,
      collection: collection,
      validation_1: validation
    } do
      # Make the GET request for a specific validation
      conn = get(conn, "/api/json/datasets/#{collection.id}/validations/#{validation.id}")

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == validation.id
      assert data["attributes"]["file_url"] == validation.file_url
      assert data["type"] == "validations"
    end

    test "create validation succeeded", %{
      conn: conn,
      collection: collection
    } do
      # Make the request to create a validation
      conn =
        post(conn, "/api/json/datasets/#{collection.id}/validations", %{
          "data" => %{
            "type" => "validations",
            "attributes" => %{
              "file_url" => "test/support/fixtures/files/NEW-validation_dwca.zip",
              "collection" => collection
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %Validation{} = validation} =
               Validation.get_by_id(data["id"], tenant: collection.id)

      assert validation.file_url == data["attributes"]["file_url"]

      assert data["attributes"]["file_url"] ==
               "test/support/fixtures/files/NEW-validation_dwca.zip"
    end

    test "update validation succeeded", %{
      conn: conn,
      collection: collection,
      validation_1: validation
    } do
      # Make the PATCH request to update the validation
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}/validations/#{validation.id}", %{
          "data" => %{
            "id" => validation.id,
            "type" => "validations",
            "attributes" => %{
              "file_url" => "UPDATED-URL"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == validation.id
      assert data["attributes"]["file_url"] == "UPDATED-URL"

      # Verify the update in the database
      assert {:ok, %Validation{} = updated_validation} =
               Validation.get_by_id(validation.id, tenant: collection.id)

      assert updated_validation.file_url == "UPDATED-URL"
    end

    test "delete validation succeeded", %{
      conn: conn,
      collection: collection,
      validation_1: validation
    } do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/validations/#{validation.id}")

      # Verify that the validation no longer exists in the database
      assert {:error, _} = Validation.get_by_id(validation.id, tenant: collection.id)
    end

    test "delete validation fails", %{conn: conn, collection: collection} do
      # Make the DELETE request with a non-existent ID
      conn =
        delete(conn, "/api/json/datasets/#{collection.id}/validations/app_02y2hKljGzKUvuLEL2s16m")

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No validations record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end

    test "enqueue validation succeeded", %{
      conn: conn,
      collection: collection,
      validation_1: validation
    } do
      # Make the PATCH request to enqueue the validation
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}/validations/#{validation.id}/enqueue", %{
          "data" => %{
            "id" => validation.id,
            "type" => "validations"
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == validation.id
      assert data["type"] == "validations"

      # Verify the state change in the database
      assert {:ok, %Validation{} = updated_validation} =
               Validation.get_by_id(validation.id, tenant: collection.id)

      # The state should be changed to "queued" after enqueue action
      assert updated_validation.state == :queued
    end
  end
end
