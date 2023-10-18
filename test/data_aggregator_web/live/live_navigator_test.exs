defmodule DataAggregatorWeb.LiveNavigatorTest do
  use DataAggregatorWeb.ConnCase

  test "[/] renders sidebar nav with active_link set to dashboard", %{conn: conn} do
    conn = get(conn, "/")

    assert conn.assigns.active_link == :dashboard
  end

  test "[/imports] renders sidebar nav with active_link set to imports", %{conn: conn} do
    conn = get(conn, "/imports")

    assert conn.assigns.active_link == :imports
  end
end
