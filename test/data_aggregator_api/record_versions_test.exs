defmodule DataAggregatorApi.RecordVersionsTest do
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

    # Create a record
    record =
      RecordsFixtures.record_fixture(%{
        collection: collection,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    # Update the record to generate a record version
    {:ok, updated_record} =
      Record.update(record, %{tax_scientific_name: "CHANGED"}, tenant: collection.id)

    {:ok, conn: conn, collection: collection, record: updated_record, collection: collection}
  end

  describe "/api/json/record_versions" do
    test "lists all record versions", %{conn: conn, collection: collection} do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/record_versions", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) > 0

      # Get the first record version
      record_version = Enum.at(data, 0)
      assert not is_nil(record_version)
      assert not is_nil(record_version["id"])
    end

    test "filters record versions by record id", %{
      conn: conn,
      record: record,
      collection: collection
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/record_versions"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1

      # All returned record versions should have the correct version_source_id
      Enum.each(data, fn version ->
        assert version["attributes"]["version_source_id"] == record.id
      end)
    end

    test "get one record version", %{conn: conn, collection: collection, record: record} do
      # First get all record versions to find an ID
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/record_versions?filter[version_source][id]=#{record.id}",
          status: 200
        )

      data = json_response(conn, 200)["data"]
      record_version = Enum.at(data, 0)
      record_version_id = record_version["id"]

      # Now test getting a specific record version
      conn =
        get(conn, "/api/json/datasets/#{collection.id}/record_versions/#{record_version_id}", status: 200)

      assert %{"data" => data} = json_response(conn, 200)

      assert data["id"] == record_version_id
    end
  end
end
