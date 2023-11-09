defmodule DataAggregatorWeb.RecordLiveTest do
  use DataAggregatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import DataAggregator.RecordsFixtures

  @update_attrs %{
    mte_material_entity_id: "record2",
    tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
  }

  @invalid_attrs %{mte_material_entity_id: nil, tax_scientific_name: nil}

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
  end

  describe "Preview" do
    setup [:create_record]

    test "displays preview within sidebar", %{conn: conn, record: record} do
      {:ok, show_live, _html} = live(conn, ~p"/records")

      assert show_live
             |> element("tbody > tr > td", record.tax_scientific_name)
             |> render_click() =~
               record.tax_scientific_name
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

      assert_patch(show_live, ~p"/records/#{record}")

      html = render(show_live)
      assert html =~ "Record updated successfully"
    end
  end
end
