defmodule DataAggregatorWeb.LiveState do
  @moduledoc """
  LiveView hook to maintain global state for the application.
  """

  import Phoenix.LiveView, only: [attach_hook: 4]
  import Phoenix.Component, only: [assign: 2, update: 3]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(sidebar_nav: false)
     |> assign(environment: Application.get_env(:data_aggregator, :environment))
     |> attach_hook(:global_state, :handle_event, &handle_event/3)}
  end

  defp handle_event("toggle-sidebar-nav", _params, socket) do
    {:halt, socket |> update(:sidebar_nav, &(!&1))}
  end

  defp handle_event(_event, _params, socket), do: {:cont, socket}
end
