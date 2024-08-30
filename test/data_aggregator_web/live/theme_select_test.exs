defmodule DataAggregatorWeb.ThemeSelectTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "theme select" do
    @tag authenticated: true
    test "applies default theme to system", %{conn: conn} do
      {:ok, _, html} = live(conn, "/")
      assert html =~ "hero-computer-desktop size-6 swap-off"
      assert html =~ "hero-moon size-6 swap-on"
      assert html =~ "hero-sun size-6 swap-on"
    end

    @tag authenticated: true
    test "cycles theme to dark on click", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      assert html =~ "hero-computer-desktop size-6 swap-off"
      assert html =~ "hero-moon size-6 swap-on"
      assert html =~ "hero-sun size-6 swap-on"

      html =
        assert view
               |> element("#theme_selector")
               |> render_click()

      assert html =~ "hero-computer-desktop size-6"
      assert html =~ "hero-moon size-6 swap-off"
      assert html =~ "hero-sun size-6 swap-on"
    end

    @tag authenticated: true
    test "cycles theme to light on click", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      assert html =~ "hero-computer-desktop size-6 swap-off"
      assert html =~ "hero-moon size-6 swap-on"
      assert html =~ "hero-sun size-6 swap-on"

      html =
        assert view
               |> element("#theme_selector")
               |> render_click()

      assert html =~ "hero-computer-desktop size-6"
      assert html =~ "hero-moon size-6 swap-off"
      assert html =~ "hero-sun size-6 swap-on"

      html =
        assert view
               |> element("#theme_selector")
               |> render_click()

      assert html =~ "hero-computer-desktop size-6"
      assert html =~ "hero-moon size-6 swap-on"
      assert html =~ "hero-sun size-6 swap-off"
    end
  end
end
