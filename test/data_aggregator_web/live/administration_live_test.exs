defmodule DataAggregatorWeb.AdministrationLiveTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Administration Index" do
    @tag authenticated: true
    test "redirects to / for empty roles", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/administration")

      assert path == ~p"/collections"
    end

    @tag authenticated: "data_administrator"
    test "redirects to / for role data_administrator", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/administration")

      assert path == ~p"/collections"
    end

    @tag authenticated: "collection_digitizer"
    test "renders /administration for role collection_digitizer", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/administration")

      assert html =~ "Administration"
    end

    @tag authenticated: "admin"
    test "renders /administration for role admin", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/administration")

      assert html =~ "Administration"
    end
  end
end
