defmodule DataAggregatorWeb.LiveNavigatorTest do
  use DataAggregatorWeb.ConnCase

  test "[/] renders sidebar nav with active_link set to dashboard", %{conn: conn} do
    conn = get(conn, "/")

    assert conn.assigns.active_link == :dashboard
  end

  test "[/records] renders sidebar nav with active_link set to import records", %{
    conn: conn
  } do
    conn = get(conn, "/records")

    assert conn.assigns.active_link == :records
  end
end
