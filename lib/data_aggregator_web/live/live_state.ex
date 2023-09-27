defmodule DataAggregatorWeb.LiveState do
  @moduledoc """
  LiveView hook to maintain global state for the application.
  """

  import Phoenix.LiveView, only: [attach_hook: 4]
  import Phoenix.Component, only: [assign: 2]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(sidebar_nav: false)
     |> attach_hook(:global_state, :handle_event, &handle_event/3)}
  end

  defp handle_event("toggle-sidebar-nav", _params, socket) do
    {:halt, socket |> assign(sidebar_nav: !socket.assigns.sidebar_nav)}
  end

  defp handle_event(_event, _params, socket), do: {:cont, socket}
end
