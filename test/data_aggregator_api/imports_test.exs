defmodule DataAggregatorApi.ImportsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Import
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

    # Create imports
    import_1 = Import.create!(collection, tenant: collection)

    import_2 = Import.create!(collection, %{state: :imported}, tenant: collection)

    import_3 = Import.create!(collection, tenant: collection)

    {:ok, conn: conn, collection: collection, import_1: import_1, import_2: import_2, import_3: import_3}
  end

  describe "/api/json/datasets/:collection_id/imports" do
    test "lists all imports", %{
      conn: conn,
      collection: collection,
      import_1: import_1,
      import_2: import_2,
      import_3: import_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/imports", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] in [import_1.id, import_2.id, import_3.id]
      assert Enum.at(data, 1)["id"] in [import_1.id, import_2.id, import_3.id]
      assert Enum.at(data, 2)["id"] in [import_1.id, import_2.id, import_3.id]
      assert Enum.at(data, 3) == nil
    end

    test "filters imports by state", %{
      conn: conn,
      collection: collection,
      import_2: import_2
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/imports?filter[state]=imported"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == import_2.id
      assert Enum.at(data, 0)["attributes"]["state"] == "imported"
    end

    test "get one import", %{
      conn: conn,
      collection: collection,
      import_1: import_1
    } do
      # Make the request
      conn =
        get(conn, "/api/json/datasets/#{collection.id}/imports/#{import_1.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert data
      assert data["id"] == import_1.id
    end

    test "create import succeeded", %{
      conn: conn,
      collection: collection
    } do
      # Mock file path for testing
      path = "test/support/fixtures/files/museum-dataset-import-example-xs.csv"

      # Make the request to create an import
      conn =
        post(conn, "/api/json/datasets/#{collection.id}/imports", %{
          "data" => %{
            "type" => "imports",
            "attributes" => %{
              "path" => path,
              "collection" => collection
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %Import{} = import_from_db} =
               Import.get_by_id(data["id"], tenant: collection.id)

      assert import_from_db.collection_id == collection.id
      assert import_from_db.state == :pending
    end

    test "update import succeeded", %{
      conn: conn,
      collection: collection,
      import_1: import_1
    } do
      # Make the PATCH request to update the import
      conn =
        patch(
          conn,
          "/api/json/datasets/#{collection.id}/imports/#{import_1.id}/update_mapping",
          %{
            "data" => %{
              "id" => import_1.id,
              "type" => "imports",
              "attributes" => %{
                "columns" => [
                  %{
                    "name" => "Scientific Name",
                    "mapped_to" => "tax_scientific_name"
                  },
                  %{
                    "name" => "Catalog Number",
                    "mapped_to" => "mte_catalog_number"
                  }
                ]
              }
            }
          }
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == import_1.id

      # Verify the update in the database
      assert {:ok, %Import{} = updated_import} =
               Import.get_by_id(import_1.id, tenant: collection.id)

      assert length(updated_import.columns) == 2

      Enum.each(updated_import.columns, fn column ->
        assert column.name in ["Scientific Name", "Catalog Number"]
        assert column.mapped_to in ["tax_scientific_name", "mte_catalog_number"]
      end)
    end

    test "delete import succeeds", %{
      conn: conn,
      collection: collection,
      import_1: import_1
    } do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/imports/#{import_1.id}")

      # Verify that the import no longer exists in the database
      assert {:error, _} = Import.get_by_id(import_1.id, tenant: collection.id)
    end

    test "delete import fails", %{conn: conn, collection: collection} do
      # Make the DELETE request with a non-existent ID
      conn =
        delete(
          conn,
          "/api/json/datasets/#{collection.id}/imports/if_02y2hKljGzKUvuLEL2s16m"
        )

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert error
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No imports record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
