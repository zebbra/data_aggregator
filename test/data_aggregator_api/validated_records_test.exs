defmodule DataAggregatorApi.ValidatedRecordsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord
  alias DataAggregator.RecordsFixtures
  alias DataAggregator.ValidationResponseFixtures
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

    # Create validated_records
    validated_record_1 =
      ValidationResponseFixtures.validated_record_fixture(%{
        record: record_1,
        collection: collection,
        mte_catalog_number: record_1.mte_catalog_number,
        tax_scientific_name: record_1.tax_scientific_name
      })

    validated_record_2 =
      ValidationResponseFixtures.validated_record_fixture(%{
        record: record_2,
        collection: collection,
        mte_catalog_number: record_2.mte_catalog_number,
        tax_scientific_name: record_2.tax_scientific_name
      })

    validated_record_3 =
      ValidationResponseFixtures.validated_record_fixture(%{
        record: record_3,
        collection: collection,
        mte_catalog_number: record_3.mte_catalog_number,
        tax_scientific_name: record_3.tax_scientific_name
      })

    {:ok,
     conn: conn,
     collection: collection,
     validated_record_1: validated_record_1,
     validated_record_2: validated_record_2,
     validated_record_3: validated_record_3}
  end

  describe "/api/json/datasets/:collection_id/validated_records" do
    test "lists all validated_records", %{
      conn: conn,
      collection: collection,
      validated_record_1: validated_record_1,
      validated_record_2: validated_record_2,
      validated_record_3: validated_record_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/validated_records", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] in [
               validated_record_1.id,
               validated_record_2.id,
               validated_record_3.id
             ]

      assert Enum.at(data, 1)["id"] in [
               validated_record_1.id,
               validated_record_2.id,
               validated_record_3.id
             ]

      assert Enum.at(data, 2)["id"] in [
               validated_record_1.id,
               validated_record_2.id,
               validated_record_3.id
             ]

      assert Enum.at(data, 3) == nil
    end

    test "filters validated_records by mte_catalog_number succeeded", %{
      conn: conn,
      collection: collection,
      validated_record_1: validated_record_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/validated_records?filter[mte_catalog_number]=#{validated_record_1.mte_catalog_number}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == validated_record_1.id

      assert Enum.at(data, 0)["attributes"]["mte_catalog_number"] ==
               validated_record_1.mte_catalog_number
    end

    test "get one validated_record", %{
      conn: conn,
      collection: collection,
      validated_record_1: validated_record
    } do
      # Make the request
      conn =
        get(conn, "/api/json/datasets/#{collection.id}/validated_records/#{validated_record.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == validated_record.id
    end

    test "update validated_record succeeded", %{
      conn: conn,
      collection: collection,
      validated_record_1: validated_record
    } do
      # Make the PATCH request to update the validated_record
      conn =
        patch(
          conn,
          "/api/json/datasets/#{collection.id}/validated_records/#{validated_record.id}",
          %{
            "data" => %{
              "id" => validated_record.id,
              "type" => "validated_records",
              "attributes" => %{
                "mte_catalog_number" => "UPDATED ONCE",
                "tax_scientific_name" => "UPDATED TWICE"
              }
            }
          }
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == validated_record.id
      assert data["attributes"]["mte_catalog_number"] == "UPDATED ONCE"
      assert data["attributes"]["tax_scientific_name"] == "UPDATED TWICE"

      # Verify the update in the database
      assert {:ok, %ValidatedRecord{} = updated_validated_record} =
               ValidatedRecord.get_by_id(validated_record.id, tenant: collection.id)

      assert updated_validated_record.mte_catalog_number == "UPDATED ONCE"
      assert updated_validated_record.tax_scientific_name == "UPDATED TWICE"
    end

    test "delete validated_record succeeds", %{
      conn: conn,
      collection: collection,
      validated_record_1: validated_record
    } do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/validated_records/#{validated_record.id}")

      # Verify that the dataset no longer exists in the database
      assert {:error, _} = ValidatedRecord.get_by_id(validated_record.id, tenant: collection.id)
    end

    test "delete validated_record fails", %{conn: conn, collection: collection} do
      # Make the DELETE request with a non-existent ID
      conn =
        delete(
          conn,
          "/api/json/datasets/#{collection.id}/validated_records/apr_02y2hKljGzKUvuLEL2s16m"
        )

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No validated_records record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
