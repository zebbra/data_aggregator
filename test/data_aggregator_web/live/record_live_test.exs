defmodule DataAggregatorWeb.RecordLiveTest do
  use DataAggregatorWeb.ConnCase

  import Phoenix.LiveViewTest
  import DataAggregator.RecordsFixtures

  @create_attrs %{
    materialEntityID: "record1",
    scientificName: "06809dc5-f143-459a-be1a-6f03e63fc083"
  }
  @update_attrs %{
    materialEntityID: "record2",
    scientificName: "06809dc5-f143-459a-be1a-6f03e63fc083"
  }
  @invalid_attrs %{materialEntityID: nil, scientificName: nil}

  defp create_record(_) do
    record = record_fixture()

    %{record: record}
  end

  describe "Index" do
    setup [:create_record]

    test "lists all records", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/records")

      assert html =~ "Listing Records"
    end

    test "saves new record", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/records")

      assert index_live |> element("a", "New Record") |> render_click() =~
               "New Record"

      assert_patch(index_live, ~p"/records/new")

      assert index_live
             |> form("#record-form", record: @invalid_attrs)
             |> render_change() =~ "is required"

      assert index_live
             |> form("#record-form", record: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/records")

      html = render(index_live)
      assert html =~ "Record created successfully"
    end

    test "updates record in listing", %{conn: conn, record: record} do
      {:ok, index_live, _html} = live(conn, ~p"/records")

      assert index_live
             |> element("#records-#{record.id} a", "Edit")
             |> render_click() =~
               "Edit Record"

      assert_patch(index_live, ~p"/records/#{record}/edit")

      assert index_live
             |> form("#record-form", record: @invalid_attrs)
             |> render_change() =~ "is required"

      assert index_live
             |> form("#record-form", record: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/records")

      html = render(index_live)
      assert html =~ "Record updated successfully"
    end

    test "deletes record in listing", %{conn: conn, record: record} do
      {:ok, index_live, _html} = live(conn, ~p"/records")

      assert index_live
             |> element("#records-#{record.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#records-#{record.id}")
    end
  end

  describe "Show" do
    setup [:create_record]

    test "displays record", %{conn: conn, record: record} do
      {:ok, _show_live, html} = live(conn, ~p"/records/#{record}")

      assert html =~ "Show Record"
    end

    test "updates record within modal", %{conn: conn, record: record} do
      {:ok, show_live, _html} = live(conn, ~p"/records/#{record}")

      assert show_live |> element("a", "Edit Record") |> render_click() =~
               "Edit Record"

      assert_patch(show_live, ~p"/records/#{record}/show/edit")

      assert show_live
             |> form("#record-form", record: @invalid_attrs)
             |> render_change() =~ "is required"

      assert show_live
             |> form("#record-form", record: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/records")

      html = render(show_live)
      assert html =~ "Record updated successfully"
    end
  end
end
