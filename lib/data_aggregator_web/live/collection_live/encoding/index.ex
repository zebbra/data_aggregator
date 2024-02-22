defmodule DataAggregatorWeb.CollectionLive.Encoding.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Record

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

  @impl true
  def handle_event("encode_collection", _params, socket) do
    Task.start(fn ->
      collection = socket.assigns.collection

      collection.records
      |> Task.async_stream(&Record.enqueue_encoder!(&1))
      |> Stream.run()

      # we update the encoding state after the encoding has been queued
      send(self(), {:encoding_state, :encoding})
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:encoding_state, state}, socket) do
    {:noreply, assign(socket, encoding_state: state)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Encodings"m)
  end
end
