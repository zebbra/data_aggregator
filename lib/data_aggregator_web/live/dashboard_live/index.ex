defmodule DataAggregatorWeb.DashboardLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="home">
      <.header><%= ~t"Dashboard"m %></.header>
    </.page>
    """
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Dashboard"m)
  end
end
