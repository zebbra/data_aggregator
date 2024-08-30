defmodule DataAggregatorWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DataAggregatorWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use DataAggregatorWeb, :verified_routes
      use DataAggregator.TestHelpers

      # Import conveniences for testing with connections
      import DataAggregatorWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn

      # The default endpoint for testing
      @endpoint DataAggregatorWeb.Endpoint
    end
  end

  setup tags do
    DataAggregator.DataCase.setup_sandbox(tags)

    conn = Phoenix.ConnTest.build_conn()

    if tags[:authenticated] do
      roles =
        tags
        |> Map.get(:authenticated)
        |> List.wrap()
        |> Enum.filter(&(&1 != true))

      user = DataAggregator.AccountsFixtures.user_fixture(%{roles: roles})

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> AshAuthentication.Phoenix.Plug.store_in_session(user)

      {:ok, conn: conn}
    else
      {:ok, conn: conn}
    end
  end
end
