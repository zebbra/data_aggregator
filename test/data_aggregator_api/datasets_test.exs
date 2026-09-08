defmodule DataAggregatorApi.DatasetsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Collection
  alias DataAggregatorApi.HelpersTest

  setup %{conn: conn} do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
    stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

    # Create a test user with admin role
    user =
      AccountsFixtures.user_fixture(%{
        email: "john.doe@example.com",
        password: "secret42",
        roles: ["admin", "collection_administrator", "data_digitizer"]
      })

    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)

    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")
      |> put_req_header("authorization", token)

    {:ok, conn: conn}
  end

  describe "/api/json/datasets" do
    test "lists all datasets", %{conn: conn} do
      # Create some test collections
      collection_1 = HelpersTest.setup_collection()
      collection_2 = HelpersTest.setup_collection()
      collection_3 = HelpersTest.setup_collection()

      # Make the request
      conn = get(conn, "/api/json/datasets", status: 200)

      # Asert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] in [collection_1.id, collection_2.id, collection_3.id]
      assert Enum.at(data, 1)["id"] in [collection_1.id, collection_2.id, collection_3.id]
      assert Enum.at(data, 2)["id"] in [collection_1.id, collection_2.id, collection_3.id]
      assert Enum.at(data, 3) == nil
    end

    test "filters datasets by grscicoll_reference", %{conn: conn} do
      # Create some test collections
      collection_1 = HelpersTest.setup_collection()
      HelpersTest.setup_collection()
      HelpersTest.setup_collection()

      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets?filter[grscicoll_reference]=#{collection_1.grscicoll_reference}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == collection_1.id

      assert Enum.at(data, 0)["attributes"]["grscicoll_reference"] ==
               collection_1.grscicoll_reference
    end

    test "get one dataset", %{
      conn: conn
    } do
      # Create a test collection
      collection = HelpersTest.setup_collection()

      # Make the request
      conn =
        get(conn, "/api/json/datasets/#{collection.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert data
      assert data["id"] == collection.id
    end

    test "create dataset", %{conn: conn} do
      # Make the request with a filter
      conn =
        post(conn, "/api/json/datasets", %{
          "data" => %{
            "type" => "collection",
            "attributes" => %{
              "description" => "Dataset Number One",
              "grscicoll_reference" => "322ce107-3156-4420-8a2b-7f17efeaa472",
              "name" => "Dataset One",
              "type" => "botany"
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %Collection{} = collection} = Collection.get_by_id(data["id"])
      assert collection.grscicoll_reference == data["attributes"]["grscicoll_reference"]
      assert collection.description == data["attributes"]["description"]

      assert data["attributes"]["description"] == "Dataset Number One"
      assert data["attributes"]["type"] == "botany"

      # the name (among other data) is fetched from the GBIF API
      assert data["attributes"]["name"] == "Herbarium - Universität Zürich"

      assert data["attributes"]["grscicoll_institution_name"] ==
               "Universität Zürich"
    end

    test "update dataset", %{conn: conn} do
      # Create a test collection
      collection = HelpersTest.setup_collection()

      # Make the PATCH request to update the dataset
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}", %{
          "data" => %{
            "id" => collection.id,
            "type" => "collection",
            "attributes" => %{
              "description" => "Updated Description",
              "name" => "Updated Dataset Name"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == collection.id
      assert data["attributes"]["description"] == "Updated Description"
      assert data["attributes"]["name"] == "Updated Dataset Name"

      # Verify the update in the database
      assert {:ok, %Collection{} = updated_collection} = Collection.get_by_id(collection.id)
      assert updated_collection.description == "Updated Description"
      assert updated_collection.name == "Updated Dataset Name"
      # The grscicoll_reference should remain unchanged
      assert updated_collection.grscicoll_reference == collection.grscicoll_reference
    end

    test "delete dataset succeeds", %{conn: conn} do
      # Create a test collection
      collection = HelpersTest.setup_collection(%{description: "WOW"})

      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}")

      # Verify that the dataset no longer exists in the database
      assert {:error, _} = Collection.get_by_id(collection.id)
    end

    test "delete dataset fails", %{conn: conn} do
      # Create a test collection
      HelpersTest.setup_collection(%{description: "WOW"})

      # Make the DELETE request
      conn = delete(conn, "/api/json/datasets/set_02y2QjtjI7sOmoAnmP0W1D")

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert error
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No collection record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
