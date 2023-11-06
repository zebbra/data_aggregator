defmodule DataAggregatorWeb.Plug.Health do
  @moduledoc """
  Simple plug to respond to health checks.
  """

  import Plug.Conn

  @default_path "/health"
  def init(opts), do: opts |> Keyword.put_new(:path, @default_path)

  def call(%Plug.Conn{request_path: request_path} = conn, opts) do
    case Keyword.get(opts, :path) do
      ^request_path -> conn |> send_resp(200, "OK") |> halt()
      _ -> conn
    end
  end

  def call(conn, _opts), do: conn
end
