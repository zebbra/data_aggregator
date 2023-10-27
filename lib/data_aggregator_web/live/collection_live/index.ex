defmodule DataAggregatorWeb.CollectionLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Platform.Collection

  import DataAggregatorWeb.QueryBuilder

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    sort = Map.get(params, "order_by", nil)
    collections = Collection.read!(%{sort: sort})

    socket =
      socket
      |> assign_current_sort(params)
      |> assign_current_path_params(params)
      |> stream(:collections, collections)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Collection"m)
    |> assign(:collection, Collection.get_by_id!(id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Collection"m)
    |> assign(:collection, Collection.get_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Collection"m)
    |> assign(:collection, %Collection{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Listing Collections"m)
    |> assign(:collection, nil)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.CollectionLive.FormComponent, {:saved, collection}},
        socket
      ) do
    {:noreply, stream_insert(socket, :collections, collection)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    collection = Collection.get_by_id!(id)
    :ok = Collection.destroy(collection)

    {:noreply, stream_delete(socket, :collections, collection)}
  end

  @impl true
  def handle_event("toggle-filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end
end
