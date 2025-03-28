defmodule DataAggregatorApi.RecordsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Record
  alias DataAggregator.RecordsFixtures
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
      |> put_req_header("api_key", token)

    # Create a test collection
    collection = HelpersTest.setup_collection()

    # Create records
    record_1 =
      RecordsFixtures.record_fixture(%{
        collection: collection,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    record_2 =
      RecordsFixtures.record_fixture(%{
        collection: collection,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    record_3 =
      RecordsFixtures.record_fixture(%{
        collection: collection,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    {:ok, conn: conn, collection: collection, record_1: record_1, record_2: record_2, record_3: record_3}
  end

  describe "/api/json/datasets/:collection_id/records" do
    test "lists all records", %{
      conn: conn,
      collection: collection,
      record_1: record_1,
      record_2: record_2,
      record_3: record_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/records", status: 200)

      # Asert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] == record_1.id
      assert Enum.at(data, 1)["id"] == record_2.id
      assert Enum.at(data, 2)["id"] == record_3.id
      assert Enum.at(data, 3) == nil
    end

    test "filters records by mte_catalog_number succeeded", %{
      conn: conn,
      collection: collection,
      record_1: record_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/records?filter[mte_catalog_number]=#{record_1.mte_catalog_number}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == record_1.id

      assert Enum.at(data, 0)["attributes"]["mte_catalog_number"] ==
               record_1.mte_catalog_number
    end

    test "get one record", %{
      conn: conn,
      collection: collection,
      record_1: record
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/records/#{record.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == record.id
    end

    test "create record succeeded", %{
      conn: conn,
      collection: collection
    } do
      # Make the request with a filter
      conn =
        post(conn, "/api/json/datasets/#{collection.id}/records", %{
          "data" => %{
            "type" => "records",
            "attributes" => %{
              "mte_catalog_number" => "1234-asdf-catalog-number",
              "tax_scientific_name" => "1234-asdf-scientific-name",
              "collection" => collection,
              "collection_id" => collection.id
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %Record{} = record} = Record.get_by_id(data["id"], tenant: collection.id)
      assert record.mte_catalog_number == data["attributes"]["mte_catalog_number"]
      assert record.tax_scientific_name == data["attributes"]["tax_scientific_name"]

      assert data["attributes"]["mte_catalog_number"] == "1234-asdf-catalog-number"
      assert data["attributes"]["tax_scientific_name"] == "1234-asdf-scientific-name"
    end

    test "update record succeeded", %{
      conn: conn,
      collection: collection,
      record_1: record
    } do
      # Make the PATCH request to update the record
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}/records/#{record.id}", %{
          "data" => %{
            "id" => record.id,
            "type" => "records",
            "attributes" => %{
              "mte_catalog_number" => "UPDATED ONCE",
              "tax_scientific_name" => "UPDATED TWICE"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == record.id
      assert data["attributes"]["mte_catalog_number"] == "UPDATED ONCE"
      assert data["attributes"]["tax_scientific_name"] == "UPDATED TWICE"

      # Verify the update in the database
      assert {:ok, %Record{} = updated_record} =
               Record.get_by_id(record.id, tenant: collection.id)

      assert updated_record.mte_catalog_number == "UPDATED ONCE"
      assert updated_record.tax_scientific_name == "UPDATED TWICE"
    end

    test "delete record succeeds", %{conn: conn, collection: collection, record_1: record} do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/records/#{record.id}")

      # Verify that the dataset no longer exists in the database
      assert {:error, _} = Record.get_by_id(record.id, tenant: collection.id)
    end

    test "delete record fails", %{conn: conn, collection: collection} do
      # Make the DELETE request
      conn =
        delete(conn, "/api/json/datasets/#{collection.id}/records/rec_02y2hKljGzKUvuLEL2s16m")

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No records record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
