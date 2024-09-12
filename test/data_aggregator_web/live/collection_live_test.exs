defmodule DataAggregatorWeb.CollectionLiveTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true
  use Mimic

  import Phoenix.LiveViewTest

  alias Ash.Error.Forbidden
  alias DataAggregator.Gbif

  setup do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

    :ok
  end

  describe "Collection Index" do
    @tag authenticated: true
    test "raise Ash.Error.Forbidden for empty roles", %{conn: conn} do
      assert_raise Forbidden, fn -> live(conn, ~p"/collections") end
    end

    @tag authenticated: "data_administrator"
    test "renders /collections for role data_administrator", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/collections")

      assert html =~ "Collections"
    end

    @tag authenticated: "collection_digitizer"
    test "renders /collections for role collection_digitizer", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/collections")

      assert html =~ "Collections"
    end

    @tag authenticated: "admin"
    test "renders /collections for role admin", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/collections")

      assert html =~ "Collections"
    end
  end

  describe "Collection New" do
    @tag authenticated: true
    test "redirects to / for empty roles", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/collections/new")

      assert path == ~p"/"
    end

    @tag authenticated: "data_administrator"
    test "redirects to / for role data_administrator", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/collections/new")

      assert path == ~p"/"
    end

    @tag authenticated: "collection_digitizer"
    test "renders /collections/new for role collection_digitizer", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/collections/new")

      assert html =~ "Collections"
    end

    @tag authenticated: "admin"
    test "renders /collections/new for role admin", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/collections/new")

      assert html =~ "Collections"
    end
  end
end
