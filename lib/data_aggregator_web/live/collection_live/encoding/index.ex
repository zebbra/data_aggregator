defmodule DataAggregatorWeb.CollectionLive.Encoding.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]
  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      assign(socket, :collection, get_collection(id))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <.collection_header collection={@collection} current={:encodings} />
    </.page>
    """
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Encodings"m)
  end
end
