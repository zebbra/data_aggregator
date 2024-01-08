defmodule DataAggregatorWeb.CollectionLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    results = Collection.read!(load: [:records_count, :digitizing_progress])
    socket = stream(socket, :results, results)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Collection"m)
    |> assign(
      :collection,
      Collection.get_by_id!(id, load: [:records_count, :digitizing_progress])
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Collection"m)
    |> assign(
      :collection,
      Collection.get_by_id!(id, load: [:records_count, :digitizing_progress])
    )
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
    {:noreply,
     stream_insert(
       socket,
       :results,
       Records.load!(collection, [:records_count, :digitizing_progress], lazy?: true)
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    collection = Collection.get_by_id!(id)
    :ok = Collection.destroy(collection)

    {:noreply, stream_delete(socket, :results, collection)}
  end
end
