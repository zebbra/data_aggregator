defmodule DataAggregatorApi.PublicationsTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Publication
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

    # Create publications
    publication_1 =
      create_publication(%{
        collection: collection,
        name: "Test Publication 1",
        records_query: %{collection: %{id: %{eq: collection.id}}}
      })

    publication_2 =
      create_publication(%{
        collection: collection,
        name: "Test Publication 2",
        records_query: %{collection: %{id: %{eq: collection.id}}}
      })

    publication_3 =
      create_publication(%{
        collection: collection,
        name: "Test Publication 3",
        records_query: %{collection: %{id: %{eq: collection.id}}}
      })

    {:ok,
     conn: conn,
     collection: collection,
     publication_1: publication_1,
     publication_2: publication_2,
     publication_3: publication_3}
  end

  describe "/api/json/datasets/:collection_id/publications" do
    test "lists all publications", %{
      conn: conn,
      collection: collection,
      publication_1: publication_1,
      publication_2: publication_2,
      publication_3: publication_3
    } do
      # Make the request
      conn = get(conn, "/api/json/datasets/#{collection.id}/publications", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert length(data) == 3

      assert Enum.at(data, 0)["id"] in [publication_1.id, publication_2.id, publication_3.id]
      assert Enum.at(data, 1)["id"] in [publication_1.id, publication_2.id, publication_3.id]
      assert Enum.at(data, 2)["id"] in [publication_1.id, publication_2.id, publication_3.id]
      assert Enum.at(data, 3) == nil
    end

    test "filters publications by name", %{
      conn: conn,
      collection: collection,
      publication_1: publication_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/datasets/#{collection.id}/publications?filter[name]=#{publication_1.name}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == publication_1.id
      assert Enum.at(data, 0)["attributes"]["name"] == publication_1.name
    end

    test "get one publication", %{
      conn: conn,
      collection: collection,
      publication_1: publication
    } do
      # Make the request
      conn =
        get(conn, "/api/json/datasets/#{collection.id}/publications/#{publication.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == publication.id
    end

    test "create publication succeeded", %{
      conn: conn,
      collection: collection
    } do
      # Make the request with a filter
      conn =
        post(conn, "/api/json/datasets/#{collection.id}/publications", %{
          "data" => %{
            "type" => "publications",
            "attributes" => %{
              "name" => "New Test Publication",
              "records_query" => %{collection: %{id: %{eq: collection.id}}},
              "collection" => collection,
              "collection_id" => collection.id
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %Publication{} = publication} =
               Publication.get_by_id(data["id"], tenant: collection.id)

      assert publication.name == data["attributes"]["name"]

      assert data["attributes"]["name"] == "New Test Publication"
    end

    test "update publication succeeded", %{
      conn: conn,
      collection: collection,
      publication_1: publication
    } do
      # Make the PATCH request to update the publication
      conn =
        patch(conn, "/api/json/datasets/#{collection.id}/publications/#{publication.id}", %{
          "data" => %{
            "id" => publication.id,
            "type" => "publications",
            "attributes" => %{
              "name" => "UPDATED NAME"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == publication.id
      assert data["attributes"]["name"] == "UPDATED NAME"

      # Verify the update in the database
      assert {:ok, %Publication{} = updated_publication} =
               Publication.get_by_id(publication.id, tenant: collection.id)

      assert updated_publication.name == "UPDATED NAME"
    end

    test "delete publication succeeds", %{
      conn: conn,
      collection: collection,
      publication_1: publication
    } do
      # Make the DELETE request
      delete(conn, "/api/json/datasets/#{collection.id}/publications/#{publication.id}")

      # Verify that the publication no longer exists in the database
      assert {:error, _} = Publication.get_by_id(publication.id, tenant: collection.id)
    end

    test "delete publication fails", %{conn: conn, collection: collection} do
      # Make the DELETE request
      conn =
        delete(
          conn,
          "/api/json/datasets/#{collection.id}/publications/pub_02y2hKljGzKUvuLEL2s16m"
        )

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No publications record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end

  # Helper function to create a publication
  defp create_publication(attrs) do
    params =
      Map.put_new_lazy(attrs, :collection, fn ->
        RecordsFixtures.collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Publication.create!(params, tenant: params.collection)
  end
end
