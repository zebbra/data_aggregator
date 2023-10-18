defmodule DataAggregatorWeb.ImportRecordLiveTest do
  use DataAggregatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import DataAggregator.ImportRecordsFixtures

  @create_attrs %{
    unique_qualifier: "import_record1"
  }
  @update_attrs %{
    unique_qualifier: "import_record2"
  }
  @invalid_attrs %{unique_qualifier: nil}

  defp create_import_record(_) do
    import_record = import_record_fixture()

    %{import_record: import_record}
  end

  describe "Index" do
    setup [:create_import_record]

    test "lists all import_records", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/import_records")

      assert html =~ "Listing Import Records"
    end

    test "saves new import_record", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/import_records")

      assert index_live |> element("a", "New Import Record") |> render_click() =~
               "New Import Record"

      assert_patch(index_live, ~p"/import_records/new")

      assert index_live
             |> form("#import-record-form", import_record: @invalid_attrs)
             |> render_change() =~ "is required"

      assert index_live
             |> form("#import-record-form", import_record: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/import_records")

      html = render(index_live)
      assert html =~ "Import Record created successfully"
    end

    test "updates import_record in listing", %{conn: conn, import_record: import_record} do
      {:ok, index_live, _html} = live(conn, ~p"/import_records")

      assert index_live
             |> element("#import_records-#{import_record.id} a", "Edit")
             |> render_click() =~
               "Edit Import Record"

      assert_patch(index_live, ~p"/import_records/#{import_record}/edit")

      assert index_live
             |> form("#import-record-form", import_record: @invalid_attrs)
             |> render_change() =~ "is required"

      assert index_live
             |> form("#import-record-form", import_record: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/import_records")

      html = render(index_live)
      assert html =~ "Import Record updated successfully"
    end

    test "deletes import_record in listing", %{conn: conn, import_record: import_record} do
      {:ok, index_live, _html} = live(conn, ~p"/import_records")

      assert index_live
             |> element("#import_records-#{import_record.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#import_records-#{import_record.id}")
    end
  end

  describe "Show" do
    setup [:create_import_record]

    test "displays import_record", %{conn: conn, import_record: import_record} do
      {:ok, _show_live, html} = live(conn, ~p"/import_records/#{import_record}")

      assert html =~ "Show Import Record"
    end

    test "updates import_record within modal", %{conn: conn, import_record: import_record} do
      {:ok, show_live, _html} = live(conn, ~p"/import_records/#{import_record}")

      assert show_live |> element("a", "Edit Import Record") |> render_click() =~
               "Edit Import Record"

      assert_patch(show_live, ~p"/import_records/#{import_record}/show/edit")

      assert show_live
             |> form("#import-record-form", import_record: @invalid_attrs)
             |> render_change() =~ "is required"

      assert show_live
             |> form("#import-record-form", import_record: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/import_records")

      html = render(show_live)
      assert html =~ "Import Record updated successfully"
    end
  end
end
