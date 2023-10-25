defmodule DataAggregatorWeb.LiveNavigator do
  @moduledoc """
  LiveView hook to keep track of the current path in the session.
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
      case {socket.view, socket.assigns.live_action} do
        {DataAggregatorWeb.DashboardLive.Index, _} ->
          :dashboard

        {DataAggregatorWeb.ImportRecordLive.Index, _} ->
          :import_records

        {DataAggregatorWeb.CollectionLive.Index, _} ->
          :collections

        {DataAggregatorWeb.CollectionLive.Show, _} ->
          :collections

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_link: active_link)}
  end
end
