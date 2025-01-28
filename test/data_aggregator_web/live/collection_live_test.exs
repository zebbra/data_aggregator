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
      assert_raise Forbidden, fn -> live(conn, ~p"/datasets") end
    end

    @tag authenticated: "data_digitizer"
    test "renders /datasets for role data_digitizer", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/datasets")

      assert html =~ "Datasets"
    end

    @tag authenticated: "collection_administrator"
    test "renders /datasets for role collection_administrator", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/datasets")

      assert html =~ "Datasets"
    end

    @tag authenticated: "admin"
    test "renders /datasets for role admin", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/datasets")

      assert html =~ "Datasets"
    end
  end

  describe "Collection New" do
    @tag authenticated: true
    test "redirects to / for empty roles", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/datasets/new")

      assert path == ~p"/datasets"
    end

    @tag authenticated: "data_digitizer"
    test "redirects to / for role data_digitizer", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: %{}}}} = live(conn, ~p"/datasets/new")

      assert path == ~p"/datasets"
    end

    @tag authenticated: "collection_administrator"
    test "renders /datasets/new for role collection_administrator", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/datasets/new")

      assert html =~ "Datasets"
    end

    @tag authenticated: "admin"
    test "renders /datasets/new for role admin", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/datasets/new")

      assert html =~ "Datasets"
    end
  end
end
