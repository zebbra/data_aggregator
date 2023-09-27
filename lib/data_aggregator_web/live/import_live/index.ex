defmodule DataAggregatorWeb.ImportLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.Import

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
      |> assign(
        :sort_options,
        order_by_options(
          socket.assigns.active_link,
          params,
          sort_options()
        )
      )
      |> stream(:imports, imports)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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

  defp sort_options do
    [
      inserted_at: ~t"Inserted At"m,
      updated_at: ~t"Updated At"m,
      url: ~t"URL"m
    ]
  end
end
