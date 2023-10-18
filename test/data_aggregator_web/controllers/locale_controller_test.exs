defmodule PortfolioWeb.SessionControllerTest do
  use DataAggregatorWeb.ConnCase

  @path "/locale"

  test "GET #{@path}", %{conn: conn} do
    conn = get(conn, @path)
    assert conn.resp_body == "en"
  end

  test "GET #{@path}?locale=de-CH", %{conn: conn} do
    conn = get(conn, @path, locale: "de-CH")
    assert conn.resp_body == "de-CH"
  end

  test "GET #{@path} (accept-language)", %{conn: conn} do
    conn = put_req_header(conn, "accept-language", "it;q=0.9;de-CH,de;q=0.8,en;q=0.7")
    conn = get(conn, @path)
    assert conn.resp_body == "de"
  end

  test "GET #{@path}?locale=it", %{conn: conn} do
    conn = get(conn, @path, locale: "it")
    assert conn.resp_body == "en"
  end
end
