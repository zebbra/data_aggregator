defmodule DataAggregatorWeb.DashboardLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="home">
      <.header><%= ~t"Dashboard"m %></.header>
    </.page>
    """
  end
end
