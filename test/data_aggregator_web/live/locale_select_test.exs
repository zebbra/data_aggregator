defmodule DataAggregatorWeb.LocaleSelectTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "locale select" do
    @tag authenticated: :admin
    test "applies default locale to en", %{conn: conn} do
      {:ok, _, html} = live(conn, "/administration")
      assert html =~ ~s|lang=\"en\"|
      refute html =~ ~s|lang=\"fr-CH\"|
      refute html =~ ~s|lang=\"de-CH\"|
    end

    @tag authenticated: :admin
    test "applies en locale if passed as URI query", %{conn: conn} do
      {:ok, _, html} = live(conn, "/administration?locale=en")
      assert html =~ ~s|lang=\"en\"|
      refute html =~ ~s|lang=\"fr-CH\"|
      refute html =~ ~s|lang=\"de-CH\"|
    end

    @tag authenticated: :admin
    test "applies de-CH locale if passed as URI query", %{conn: conn} do
      {:ok, _, html} = live(conn, "/administration?locale=de-CH")
      refute html =~ ~s|lang=\"en\"|
      refute html =~ ~s|lang=\"fr-CH\"|
      assert html =~ ~s|lang=\"de-CH\"|
    end

    @tag authenticated: :admin
    test "applies fr-CH locale if passed as URI query", %{conn: conn} do
      {:ok, _, html} = live(conn, "/administration?locale=fr-CH")
      refute html =~ ~s|lang=\"en\"|
      assert html =~ ~s|lang=\"fr-CH\"|
      refute html =~ ~s|lang=\"de-CH\"|
    end

    @tag authenticated: :admin
    test "applies en locale if passed as URI query is not valid", %{conn: conn} do
      {:ok, _, html} = live(conn, "/administration?locale=ar")
      assert html =~ ~s|lang=\"en\"|
      refute html =~ ~s|lang=\"fr-CH\"|
      refute html =~ ~s|lang=\"de-CH\"|
    end
  end
end
