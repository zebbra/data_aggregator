defmodule DataAggregatorWeb.CollectionLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Collection

  import DataAggregatorWeb.QueryBuilder

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_current_sort(params)
      |> assign_current_path_params(params)
      |> assign_collections()

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp assign_collections(socket) do
    list_collections(socket)
  end

  defp list_collections(socket) do
    %{current_sort: current_sort} = socket.assigns

    results = Collection.read!(%{sort: current_sort}, load: [:records_count, :imports_count])

    stream_results(socket, results)
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
    {:noreply, stream_insert(socket, :results, collection)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    collection = Collection.get_by_id!(id)
    :ok = Collection.destroy(collection)

    {:noreply, stream_delete(socket, :results, collection)}
  end

  @impl true
  def handle_event("sort:select", %{"sort" => sort}, socket) do
    socket = handle_sort(socket, sort)

    {:noreply,
     patch_params(socket, %{
       sort: socket.assigns.current_sort
     })}
  end

  defp patch_params(socket, params) do
    params = Map.reject(params, &(elem(&1, 1) in ["", nil]))
    push_patch(socket, to: ~p"/collections?#{params}", replace: true)
  end
end
