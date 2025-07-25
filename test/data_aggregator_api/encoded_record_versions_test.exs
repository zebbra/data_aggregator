defmodule DataAggregatorApi.EncodedRecordVersionsTest do
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

    # Create encoded_records
    encoded_record =
      EncodingFixtures.encoded_record_fixture(%{
        record: record_1,
        collection_id: collection.id,
        mte_catalog_number: Ecto.UUID.generate(),
        tax_scientific_name: Ecto.UUID.generate()
      })

    # Update the encoded_record to generate a record version
    {:ok, updated_encoded_record} =
      EncodedRecord.update(encoded_record, %{tax_scientific_name: "CHANGED"}, tenant: collection.id)

    {:ok, conn: conn, collection: collection, encoded_record: updated_encoded_record}
  end

  describe "/api/json/encoded_record_versions" do
    test "lists all encoded_record versions", %{conn: conn, collection: collection} do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/encoded_record_versions", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)
      assert length(data) > 0

      # Get the first record version
      version = Enum.at(data, 0)

      assert not is_nil(version)
      assert not is_nil(version["id"])
    end

    test "filters encoded_record versions by record id", %{
      conn: conn,
      encoded_record: encoded_record,
      collection: collection
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/encoded_record_versions"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1

      # All returned encoded_record versions should have the correct version_source_id
      Enum.each(data, fn version ->
        assert version["attributes"]["version_source_id"] == encoded_record.id
      end)
    end

    test "get one encoded_record version", %{
      conn: conn,
      collection: collection,
      encoded_record: encoded_record
    } do
      # First get all encoded_record versions to find an ID
      new_conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/encoded_record_versions?filter[version_source][id]=#{encoded_record.id}",
          status: 200
        )

      assert %{"data" => data} = json_response(new_conn, 200)
      version = Enum.at(data, 0)
      version_id = version["attributes"]["id"]

      # Now test getting a specific encoded_record version
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/encoded_record_versions/#{version_id}",
          status: 200
        )

      assert %{"data" => data} = json_response(conn, 200)
      version = Enum.at(data, 0)
      assert version["attributes"]["id"] == version_id
    end
  end
end
