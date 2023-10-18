defmodule DataAggregatorWeb.ImportLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.Import

  @sort_options [:inserted_at, :updated_at, :url]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    imports =
      Import.read!(Map.get(params, "order_by", ""))

    socket =
      socket
      |> assign(:current_order_by, get_current_order_by(params))
      |> assign(:current_order_dir, get_current_order_dir(params))
      |> assign(
        :sort_options,
        order_by_options(
          socket.assigns.active_link,
          params,
          @sort_options
        )
      )
      |> assign(:show_filters, false)
      |> stream(:imports, imports)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Import"m)
    |> assign(:import, Import.get_by_id!(id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Import"m)
    |> assign(:import, Import.get_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Import"m)
    |> assign(:import, %Import{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Listing Imports"m)
    |> assign(:import, nil)
  end

  @impl true
  def handle_info({DataAggregatorWeb.ImportLive.FormComponent, {:saved, import}}, socket) do
    {:noreply, stream_insert(socket, :imports, import)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    import = Import.get_by_id!(id)
    :ok = Import.destroy(import)

    {:noreply, stream_delete(socket, :imports, import)}
  end

  @impl true
  def handle_event("toggle-filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end
end
