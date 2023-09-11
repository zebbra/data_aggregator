defmodule DataAggregatorWeb.DashboardLive.Index do
  use DataAggregatorWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="p-4 sm:px-6 lg:px-8">Dashboard</.header>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Dashboard"m)
    |> assign(:import, nil)
  end
end
