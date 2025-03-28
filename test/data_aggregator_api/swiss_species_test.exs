defmodule DataAggregatorApi.SwissSpeciesTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  import Mimic

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.SwissSpeciesFixtures
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

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

    # Create test swiss_species entries
    swiss_species_1 =
      SwissSpeciesFixtures.swiss_species_fixture(%{
        taxon_id_ch: 10_001,
        scientific_name: "Scientific Name 1",
        accepted_name: "Accepted Name 1",
        rank: "species"
      })

    swiss_species_2 =
      SwissSpeciesFixtures.swiss_species_fixture(%{
        taxon_id_ch: 10_002,
        scientific_name: "Scientific Name 2",
        accepted_name: "Accepted Name 2",
        rank: "genus"
      })

    swiss_species_3 =
      SwissSpeciesFixtures.swiss_species_fixture(%{
        taxon_id_ch: 10_003,
        scientific_name: "Scientific Name 3",
        accepted_name: "Accepted Name 3",
        rank: "family"
      })

    {:ok,
     conn: conn, swiss_species_1: swiss_species_1, swiss_species_2: swiss_species_2, swiss_species_3: swiss_species_3}
  end

  describe "/api/json/swiss_species" do
    test "lists all swiss_species", %{
      conn: conn,
      swiss_species_1: swiss_species_1,
      swiss_species_2: swiss_species_2,
      swiss_species_3: swiss_species_3
    } do
      # Make the request
      conn = get(conn, "/api/json/swiss_species", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      # Check that our test entries are in the response
      # Note: There might be other entries in the database due to system seeds, so we don't assert on the exact length
      assert Enum.any?(data, fn entry -> entry["id"] == swiss_species_1.id end)
      assert Enum.any?(data, fn entry -> entry["id"] == swiss_species_2.id end)
      assert Enum.any?(data, fn entry -> entry["id"] == swiss_species_3.id end)
    end

    test "filters swiss_species by scientific_name succeeded", %{
      conn: conn,
      swiss_species_1: swiss_species_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/swiss_species?filter[scientific_name]=#{swiss_species_1.scientific_name}"
        )

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == swiss_species_1.id

      assert Enum.at(data, 0)["attributes"]["scientific_name"] ==
               swiss_species_1.scientific_name
    end

    test "get one swiss_species", %{
      conn: conn,
      swiss_species_1: swiss_species
    } do
      # Make the request
      conn = get(conn, "/api/json/swiss_species/#{swiss_species.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == swiss_species.id
    end

    test "create swiss_species succeeded", %{
      conn: conn
    } do
      # Generate a unique usage_key for this test
      usage_key = :rand.uniform(1_000_000)

      # Make the request
      conn =
        post(conn, "/api/json/swiss_species", %{
          "data" => %{
            "type" => "swiss_species",
            "attributes" => %{
              "taxon_id_ch" => 10_004,
              "scientific_name" => "New Scientific Name",
              "accepted_name" => "New Accepted Name",
              "usage_key" => usage_key,
              "rank" => "species"
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %SwissSpecies{} = swiss_species} = SwissSpecies.get_by_id(data["id"])
      assert swiss_species.taxon_id_ch == data["attributes"]["taxon_id_ch"]
      assert swiss_species.scientific_name == data["attributes"]["scientific_name"]

      assert data["attributes"]["taxon_id_ch"] == 10_004
      assert data["attributes"]["scientific_name"] == "New Scientific Name"
      assert data["attributes"]["usage_key"] == usage_key
    end

    test "update swiss_species succeeded", %{
      conn: conn,
      swiss_species_1: swiss_species
    } do
      # Make the PATCH request to update the swiss_species
      conn =
        patch(conn, "/api/json/swiss_species/#{swiss_species.id}", %{
          "data" => %{
            "id" => swiss_species.id,
            "type" => "swiss_species",
            "attributes" => %{
              "scientific_name" => "UPDATED SCIENTIFIC NAME",
              "accepted_name" => "UPDATED ACCEPTED NAME"
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == swiss_species.id
      assert data["attributes"]["scientific_name"] == "UPDATED SCIENTIFIC NAME"
      assert data["attributes"]["accepted_name"] == "UPDATED ACCEPTED NAME"

      # Verify the update in the database
      assert {:ok, %SwissSpecies{} = updated_swiss_species} =
               SwissSpecies.get_by_id(swiss_species.id)

      assert updated_swiss_species.scientific_name == "UPDATED SCIENTIFIC NAME"
      assert updated_swiss_species.accepted_name == "UPDATED ACCEPTED NAME"
    end

    test "delete swiss_species succeeds", %{conn: conn, swiss_species_1: swiss_species} do
      # Make the DELETE request
      delete(conn, "/api/json/swiss_species/#{swiss_species.id}")

      # Verify that the swiss_species no longer exists in the database
      assert {:error, _} = SwissSpecies.get_by_id(swiss_species.id)
    end

    test "delete swiss_species fails", %{conn: conn} do
      # Make the DELETE request with an invalid ID
      conn = delete(conn, "/api/json/swiss_species/spc_02y2QjtjI7sOmoAnmP0de2")

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No swiss_species record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end
end
