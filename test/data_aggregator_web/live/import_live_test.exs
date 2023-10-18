defmodule DataAggregatorWeb.ImportLiveTest do
  use DataAggregatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import DataAggregator.ImportsFixtures

  @create_attrs %{url: "https://example.com"}
  @update_attrs %{url: "https://example.com"}
  @invalid_attrs %{url: nil}

  defp create_import(_) do
    import = import_fixture()
    %{import: import}
  end

  describe "Index" do
    setup [:create_import]

    test "lists all imports", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/imports")

      assert html =~ "Listing Imports"
    end

    test "saves new import", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/imports")

      assert index_live |> element("a", "New Import") |> render_click() =~
               "New Import"

      assert_patch(index_live, ~p"/imports/new")

      assert index_live
             |> form("#import-form", import: @invalid_attrs)
             |> render_change() =~ "is required"

      assert index_live
             |> form("#import-form", import: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/imports")

      html = render(index_live)
      assert html =~ "Import created successfully"
    end

    test "updates import in listing", %{conn: conn, import: import} do
      {:ok, index_live, _html} = live(conn, ~p"/imports")

      assert index_live |> element("#imports-#{import.id} a", "Edit") |> render_click() =~
               "Edit Import"

      assert_patch(index_live, ~p"/imports/#{import}/edit")

      assert index_live
             |> form("#import-form", import: @invalid_attrs)
             |> render_change() =~ "is required"

      assert index_live
             |> form("#import-form", import: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/imports")

      html = render(index_live)
      assert html =~ "Import updated successfully"
    end

    test "deletes import in listing", %{conn: conn, import: import} do
      {:ok, index_live, _html} = live(conn, ~p"/imports")

      assert index_live |> element("#imports-#{import.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#imports-#{import.id}")
    end
  end

  describe "Show" do
    setup [:create_import]

    test "displays import", %{conn: conn, import: import} do
      {:ok, _show_live, html} = live(conn, ~p"/imports/#{import}")

      assert html =~ "Show Import"
    end

    test "updates import within modal", %{conn: conn, import: import} do
      {:ok, show_live, _html} = live(conn, ~p"/imports/#{import}")

      assert show_live |> element("a", "Edit import") |> render_click() =~
               "Edit Import"

      assert_patch(show_live, ~p"/imports/#{import}/show/edit")

      assert show_live
             |> form("#import-form", import: @invalid_attrs)
             |> render_change() =~ "is required"

      assert show_live
             |> form("#import-form", import: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/imports")

      html = render(show_live)
      assert html =~ "Import updated successfully"
    end
  end
end
