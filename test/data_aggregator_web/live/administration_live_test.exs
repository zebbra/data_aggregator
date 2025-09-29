defmodule DataAggregatorWeb.AdministrationLiveTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Administration Index" do
    @tag authenticated: true
    test "redirects to / for empty roles", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/administration/users")

      assert path == ~p"/datasets"
    end

    @tag authenticated: "data_digitizer"
    test "redirects to / for role data_digitizer", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/administration/users")

      assert path == ~p"/datasets"
    end

    @tag authenticated: "collection_administrator"
    test "renders /administration for role collection_administrator", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/administration/users")

      assert html =~ "Administration"
    end

    @tag authenticated: "admin"
    test "renders /administration for role admin", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/administration/users")

      assert html =~ "Administration"
    end
  end
end
