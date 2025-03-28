defmodule DataAggregatorApi.ExportsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase
  use Oban.Testing, repo: DataAggregator.Repo

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.ExportFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Export
  alias DataAggregatorApi.HelpersTest

  @valid_custom_mapping %{
    :mte_catalog_number => "Numéro scientifique GBIF",
    :tax_family => "Famille"
  }

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
      |> put_req_header("api_key", token)

    # Create a test collection
    collection = HelpersTest.setup_collection()

    # Create exports
    export_1 = ExportFixtures.export_fixture(%{collection: collection})

    export_2 =
      ExportFixtures.export_fixture(%{
        collection: collection,
        state: :exported
      })

    export_3 = ExportFixtures.export_fixture(%{collection: collection})

    {:ok, conn: conn, collection: collection, export_1: export_1, export_2: export_2, export_3: export_3}
  end

  describe "/api/json/datasets/:collection_id/exports" do
    test "lists all exports", %{
      conn: conn,
      collection: collection,
      export_1: export_1,
      export_2: export_2,
      export_3: export_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/exports", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] in [export_1.id, export_2.id, export_3.id]
      assert Enum.at(data, 1)["id"] in [export_1.id, export_2.id, export_3.id]
      assert Enum.at(data, 2)["id"] in [export_1.id, export_2.id, export_3.id]
      assert Enum.at(data, 3) == nil
    end

    test "filters exports by state", %{
      conn: conn,
      collection: collection,
      export_2: export_2
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/exports?filter[state]=exported"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == export_2.id
      assert Enum.at(data, 0)["attributes"]["state"] == "exported"
    end

    test "get one export", %{
      conn: conn,
      collection: collection,
      export_1: export_1
    } do
      # Make the request
      conn =
        get(conn, "/api/json/datasets/#{collection.id}/exports/#{export_1.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == export_1.id
    end

    test "create export succeeded", %{
      conn: conn,
      collection: collection
    } do
      # Make the request to create an export
      conn =
        post(conn, "/api/json/datasets/#{collection.id}/exports", %{
          "data" => %{
            "type" => "exports",
            "attributes" => %{
              "name" => "Test Export",
              "collection" => collection,
              "collection_id" => collection.id,
              "header_source" => "custom_selection",
              "state" => "pending",
              "data_layer" => "raw",
              "mapping" => @valid_custom_mapping,
              "records_query" => collection.records_to_export_query
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %Export{} = export_from_db} =
               Export.get_by_id(data["id"], tenant: collection.id)

      assert export_from_db.collection_id == collection.id
      assert export_from_db.name == "Test Export"
      assert export_from_db.data_layer == :raw
      assert export_from_db.header_source == :custom_selection
      assert export_from_db.state == :pending
    end

    test "update export succeeded", %{
      conn: conn,
      collection: collection,
      export_1: export_1
    } do
      # Make the PATCH request to update the export
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}/exports/#{export_1.id}", %{
          "data" => %{
            "id" => export_1.id,
            "type" => "exports",
            "attributes" => %{
              "name" => "Updated Export Name"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == export_1.id
      assert data["attributes"]["name"] == "Updated Export Name"

      # Verify the update in the database
      assert {:ok, %Export{} = updated_export} =
               Export.get_by_id(export_1.id, tenant: collection.id)

      assert updated_export.name == "Updated Export Name"
    end

    test "delete export succeeds", %{
      conn: conn,
      collection: collection,
      export_1: export_1
    } do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/exports/#{export_1.id}")

      # Verify that the export no longer exists in the database
      assert {:error, _} = Export.get_by_id(export_1.id, tenant: collection.id)
    end

    test "delete export fails", %{conn: conn, collection: collection} do
      # Make the DELETE request with a non-existent ID
      conn =
        delete(
          conn,
          "/api/json/datasets/#{collection.id}/exports/exp_02y2hKljGzKUvuLEL2s16m"
        )

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No exports record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
