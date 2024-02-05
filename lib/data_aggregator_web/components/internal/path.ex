defmodule DataAggregatorWeb.Components.Internal.Path do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  # Assign the current path params to the socket
  def assign_current_path_params(socket, params, allowed_keys \\ ["filter", "sort", "page", "limit"]) do
    path_params =
      params |> Map.take(allowed_keys) |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    assign(socket, :current_path_params, path_params)
  end
end
