defmodule DataAggregatorApi.EncodedRecordsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.EncodingFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.EncodedRecord
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

    # Create encoded_records
    encoded_record_1 =
      EncodingFixtures.encoded_record_fixture(%{
        record: record_1,
        collection_id: collection.id,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    encoded_record_2 =
      EncodingFixtures.encoded_record_fixture(%{
        record: record_2,
        collection_id: collection.id,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    encoded_record_3 =
      EncodingFixtures.encoded_record_fixture(%{
        record: record_3,
        collection_id: collection.id,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    {:ok,
     conn: conn,
     collection: collection,
     encoded_record_1: encoded_record_1,
     encoded_record_2: encoded_record_2,
     encoded_record_3: encoded_record_3}
  end

  describe "/api/json/datasets/:collection_id/encoded_records" do
    test "lists all encoded_records", %{
      conn: conn,
      collection: collection,
      encoded_record_1: encoded_record_1,
      encoded_record_2: encoded_record_2,
      encoded_record_3: encoded_record_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/encoded_records", status: 200)

      EncodedRecord.read!(tenant: collection.id)

      # Asert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] == encoded_record_1.id
      assert Enum.at(data, 1)["id"] == encoded_record_2.id
      assert Enum.at(data, 2)["id"] == encoded_record_3.id
      assert Enum.at(data, 3) == nil
    end

    test "filters encoded_records by mte_catalog_number succeeded", %{
      conn: conn,
      collection: collection,
      encoded_record_1: encoded_record_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/encoded_records?filter[mte_catalog_number]=#{encoded_record_1.mte_catalog_number}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == encoded_record_1.id

      assert Enum.at(data, 0)["attributes"]["mte_catalog_number"] ==
               encoded_record_1.mte_catalog_number
    end

    test "get one encoded_record", %{
      conn: conn,
      collection: collection,
      encoded_record_1: encoded_record
    } do
      # Make the request
      conn =
        get(conn, "/api/json/datasets/#{collection.id}/encoded_records/#{encoded_record.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == encoded_record.id
    end

    test "update encoded_record succeeded", %{
      conn: conn,
      collection: collection,
      encoded_record_1: encoded_record
    } do
      # Make the PATCH request to update the encoded_record
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}/encoded_records/#{encoded_record.id}", %{
          "data" => %{
            "id" => encoded_record.id,
            "type" => "encoded_records",
            "attributes" => %{
              "mte_catalog_number" => "UPDATED ONCE",
              "tax_scientific_name" => "UPDATED TWICE"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == encoded_record.id
      assert data["attributes"]["mte_catalog_number"] == "UPDATED ONCE"
      assert data["attributes"]["tax_scientific_name"] == "UPDATED TWICE"

      # Verify the update in the database
      assert {:ok, %EncodedRecord{} = updated_encoded_record} =
               EncodedRecord.get_by_id(encoded_record.id, tenant: collection.id)

      assert updated_encoded_record.mte_catalog_number == "UPDATED ONCE"
      assert updated_encoded_record.tax_scientific_name == "UPDATED TWICE"
    end

    test "delete encoded_record succeeds", %{
      conn: conn,
      collection: collection,
      encoded_record_1: encoded_record
    } do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/encoded_records/#{encoded_record.id}")

      # Verify that the dataset no longer exists in the database
      assert {:error, _} = EncodedRecord.get_by_id(encoded_record.id, tenant: collection.id)
    end

    test "delete encoded_record fails", %{conn: conn, collection: collection} do
      # Make the DELETE request
      conn =
        delete(
          conn,
          "/api/json/datasets/#{collection.id}/encoded_records/enr_02y2hKljGzKUvuLEL2s16m"
        )

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No encoded_records record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
