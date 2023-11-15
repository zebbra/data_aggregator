defmodule DataAggregatorWeb.ImportLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Import

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    results = list_imports()
    socket = stream(socket, :results, results)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    import = Import.get_by_id!(id)
    :ok = Import.destroy(import)

    {:noreply, stream_delete(socket, :results, import)}
  end
end
