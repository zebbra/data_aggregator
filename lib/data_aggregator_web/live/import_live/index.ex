defmodule DataAggregatorWeb.ImportLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Platform.Import

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
      |> assign_imports()

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp assign_imports(socket) do
    list_imports(socket)
  end

  defp list_imports(socket) do
    %{current_sort: current_sort} = socket.assigns

    results = Import.read!(%{sort: current_sort}, load: :collection)

    stream_results(socket, results)
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
    push_patch(socket, to: ~p"/imports?#{params}", replace: true)
  end
end
