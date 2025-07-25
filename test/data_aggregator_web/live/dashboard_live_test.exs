defmodule DataAggregatorWeb.DashboardLiveTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    @tag authenticated: true
    test "redirects to collection", %{conn: conn} do
      # {:ok, _index_live, html} = live(conn, ~p"/")
      {:error, {:live_redirect, %{to: "/datasets"}}} = live(conn, ~p"/")
    end
  end
end
