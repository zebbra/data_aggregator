defmodule Pagify.ComponentsTest do
  @moduledoc false

  use ExUnit.Case

  alias Plug.Conn.Query

  doctest Pagify.Components, import: true

  @route_helper_opts [%{}, :posts]

  def route_helper(%{}, action, query) do
    URI.to_string(%URI{path: "/#{action}", query: Query.encode(query)})
  end
end
