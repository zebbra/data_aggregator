defmodule DataAggregatorWeb.CollectionLive.Index do
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
    <.page current="collections">
      <.header><%= ~t"Collections"m %></.header>
    </.page>
    """
  end
end
