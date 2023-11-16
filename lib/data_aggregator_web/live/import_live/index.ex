defmodule DataAggregatorWeb.ImportLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Import

  @topics ["import:created", "import:updated", "import:deleted"]

  @impl true
  def mount(_params, _session, socket) do
    # Replace with? https://hexdocs.pm/ash_phoenix/AshPhoenix.LiveView.html#keep_live/4
    # socket = socket |> assign_live(:imports, &list_imports/1, subscribe: @topics)
    if connected?(socket), do: PubSub.subscribe(@topics)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_imports()
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp list_imports do
    Import.read!(
      load: [
        :collection_name,
        :records_count,
        :attachment_filename,
        :attachment_byte_size
      ]
    )
  end

  defp assign_imports(socket) do
    results = list_imports()
    socket |> stream(:results, results)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Import"m)
    |> assign(:import, Import.get_by_id!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Listing Imports"m)
    |> assign(:import, nil)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.ImportLive.FormComponent, {:saved, import}},
        socket
      ) do
    {:noreply, stream_insert(socket, :results, import)}
  end

  def handle_info({topic, _event, _notification}, socket) when topic in @topics do
    socket = socket |> assign_imports()
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    import = Import.get_by_id!(id)
    :ok = Import.destroy(import)

    {:noreply, stream_delete(socket, :results, import)}
  end
end
