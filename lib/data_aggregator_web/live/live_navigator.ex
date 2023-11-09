defmodule DataAggregatorWeb.LiveNavigator do
  @moduledoc """
  LiveView hook to keep track of the current active link in the session.
  """

  import Phoenix.LiveView, only: [attach_hook: 4]
  import Phoenix.Component, only: [assign: 2]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_link, :handle_params, &set_active_link/3)}
  end

  defp set_active_link(_params, _url, socket) do
    active_link =
      case {to_string(socket.view), socket.assigns.live_action} do
        {"Elixir.DataAggregatorWeb.DashboardLive" <> _, _} ->
          :dashboard

        {"Elixir.DataAggregatorWeb.RecordLive" <> _, _} ->
          :records

        {"Elixir.DataAggregatorWeb.CollectionLive" <> _, _} ->
          :collections

        {"Elixir.DataAggregatorWeb.ImportLive" <> _, _} ->
          :imports

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_link: active_link)}
  end
end
