defmodule DataAggregatorApi.UsersTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase

  alias DataAggregator.Accounts.User
  alias DataAggregator.AccountsFixtures

  setup %{conn: conn} do
    # Create a test admin user for authentication
    admin_user =
      AccountsFixtures.user_fixture(%{
        email: "admin@example.com",
        password: "secret42",
        roles: ["admin"]
      })

    # Get token for authentication
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(admin_user)

    # Add request headers
    conn =
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")
      |> put_req_header("api_key", token)

    # Create test users
    user_1 =
      AccountsFixtures.user_fixture(%{
        email: "user1@example.com",
        first_name: "User",
        last_name: "One"
      })

    user_2 =
      AccountsFixtures.user_fixture(%{
        email: "user2@example.com",
        first_name: "User",
        last_name: "Two"
      })

    user_3 =
      AccountsFixtures.user_fixture(%{
        email: "user3@example.com",
        first_name: "User",
        last_name: "Three"
      })

    {:ok, conn: conn, admin_user: admin_user, user_1: user_1, user_2: user_2, user_3: user_3}
  end

  describe "/api/json/users" do
    @tag :run
    test "lists all users", %{
      conn: conn,
      user_1: user_1,
      user_2: user_2,
      user_3: user_3
    } do
      # Make the request
      conn = get(conn, "/api/json/users", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      # We expect at least 4 users (3 test users + admin user)
      assert length(data) >= 4

      # Check that our test users are in the response
      user_ids = Enum.map(data, fn user -> user["id"] end)
      assert user_1.id in user_ids
      assert user_2.id in user_ids
      assert user_3.id in user_ids
    end

    @tag :run
    test "filters users by email succeeded", %{
      conn: conn,
      user_1: user_1
    } do
      # Make the request with a filter
      conn =
        get(
          conn,
          "/api/json/users?filter[email][eq]=#{user_1.email}"
        )

      assert %{"data" => data} = json_response(conn, 200)

      # Assert on the response
      assert length(data) == 1
      assert Enum.at(data, 0)["id"] == user_1.id
      assert Enum.at(data, 0)["attributes"]["email"] == "#{user_1.email}"
    end

    @tag :run
    test "filters users by first_name succeeded", %{
      conn: conn,
      user_1: user_1,
      user_2: user_2,
      user_3: user_3
    } do
      # All test users have the same first_name "User"
      conn =
        get(
          conn,
          "/api/json/users?filter[first_name][eq]=User"
        )

      assert %{"data" => data} = json_response(conn, 200)

      # Assert on the response - should find all 3 test users
      assert length(data) >= 3

      user_ids = Enum.map(data, fn user -> user["id"] end)
      assert user_1.id in user_ids
      assert user_2.id in user_ids
      assert user_3.id in user_ids
    end

    @tag :run
    test "get one user", %{
      conn: conn,
      user_1: user
    } do
      # Make the request
      conn = get(conn, "/api/json/users/#{user.id}", status: 200)

      # Assert on the response
      assert %{"data" => data} = json_response(conn, 200)

      assert not is_nil(data)
      assert data["id"] == user.id
      assert data["attributes"]["email"] == "#{user.email}"
      assert data["attributes"]["first_name"] == user.first_name
      assert data["attributes"]["last_name"] == user.last_name
    end

    @tag :run
    test "create user succeeded", %{
      conn: conn
    } do
      # Make the request to create a user
      conn =
        post(conn, "/api/json/users", %{
          "data" => %{
            "type" => "users",
            "attributes" => %{
              "email" => "new.user@example.com",
              "first_name" => "New",
              "last_name" => "User",
              "password" => "password123",
              "roles" => ["data_digitizer"]
            }
          }
        })

      data = json_response(conn, 201)["data"]

      # Assert on the response
      assert {:ok, %User{} = user} = User.get_by_id(data["id"])
      assert "#{user.email}" == data["attributes"]["email"]
      assert user.first_name == data["attributes"]["first_name"]
      assert user.last_name == data["attributes"]["last_name"]

      assert data["attributes"]["email"] == "new.user@example.com"
      assert data["attributes"]["first_name"] == "New"
      assert data["attributes"]["last_name"] == "User"
    end

    @tag :run
    test "update user succeeded", %{
      conn: conn,
      user_1: user
    } do
      # Make the PATCH request to update the user
      conn =
        patch(conn, "/api/json/users/#{user.id}", %{
          "data" => %{
            "type" => "users",
            "attributes" => %{
              "email" => "new.user@example.com",
              "first_name" => "Updated",
              "last_name" => "User",
              "password" => "HOORRAAY",
              "roles" => ["admin"]
            }
          }
        })

      data = json_response(conn, 200)["data"]

      # Assert on the response
      assert data["id"] == user.id
      assert data["attributes"]["first_name"] == "Updated"
      assert data["attributes"]["last_name"] == "User"

      # Verify the update in the database
      assert {:ok, %User{} = updated_user} = User.get_by_id(user.id)
      assert updated_user.first_name == "Updated"
      assert updated_user.last_name == "User"
    end

    @tag :run
    test "delete user succeeds", %{conn: conn, user_1: user} do
      # Make the DELETE request
      delete(conn, "/api/json/users/#{user.id}")

      # Verify that the user no longer exists in the database
      assert {:error, _} = User.get_by_id(user.id)
    end

    @tag :run
    test "delete user fails with non-existent ID", %{conn: conn} do
      # Make the DELETE request with a non-existent ID
      conn =
        delete(conn, "/api/json/users/usr_02y2hKljGzKUvuLEL2s16m")

      errors = json_response(conn, 404)["errors"]

      error = Enum.at(errors, 0)

      # Assert on the response
      assert not is_nil(error)
      assert length(errors) == 1
      assert error["code"] == "not_found"
      assert error["detail"] =~ "No users record found with "
      assert error["status"] == "404"
      assert error["title"] =~ "Entity Not Found"
    end
  end

  describe "/api/json/users/sign_in" do
    @tag :run
    test "sign in succeeds with valid credentials", %{conn: conn} do
      # Create a user for sign in
      user =
        AccountsFixtures.user_fixture(%{
          email: "signin.test@example.com",
          password: "password123"
        })

      # Make the sign in request
      conn =
        post(conn, "/api/json/users/sign_in", %{
          "data" => %{
            "type" => "users",
            "attributes" => %{
              "email" => "signin.test@example.com",
              "password" => "password123"
            }
          }
        })

      # Assert on the response
      assert %{"data" => data, "meta" => meta} = json_response(conn, 201)

      assert data["id"] == user.id
      assert data["attributes"]["email"] == "signin.test@example.com"
      assert Map.has_key?(meta, "token")
      assert is_binary(meta["token"])
    end

    @tag :run
    test "sign in fails with invalid credentials", %{conn: conn} do
      # Create a user for sign in
      AccountsFixtures.user_fixture(%{
        email: "signin.test@example.com",
        password: "password123"
      })

      # Make the sign in request with wrong password
      conn =
        post(conn, "/api/json/users/sign_in", %{
          "data" => %{
            "type" => "users",
            "attributes" => %{
              "email" => "signin.test@example.com",
              "password" => "wrong_password"
            }
          }
        })

      # Assert on the response
      assert %{"errors" => errors} = json_response(conn, 403)
      error = Enum.at(errors, 0)
      assert error["code"] == "forbidden"
      assert error["detail"] == "forbidden"
      assert error["status"] == "403"
      assert error["title"] == "Forbidden"
    end
  end
end
