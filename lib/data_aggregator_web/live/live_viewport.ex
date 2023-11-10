defmodule DataAggregatorWeb.LiveViewport do
  @moduledoc """
  LiveView hook for responsive client viewport management.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [get_connect_params: 1]

  def on_mount(:default, _params, _session, socket) do
    viewport_width =
      socket
      |> get_connect_params()
      |> viewport_width()

    {:cont, assign(socket, :viewport_width, viewport_width)}
  end

  defp viewport_width(%{"viewport" => viewport} = _params) do
    viewport["width"]
  end

  defp viewport_width(_params) do
    # default for testing
    0
  end
end
