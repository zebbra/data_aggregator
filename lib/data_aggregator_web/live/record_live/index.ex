defmodule DataAggregatorWeb.RecordLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Data.Record

  @sort_options [:inserted_at, :updated_at, :unique_qualifier]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    records =
      Record.read!(%{sort: Map.get(params, "order_by", "")})

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
      |> stream(:records, records)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Record"m)
    |> assign(:record, Record.get_by_id!(id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Record"m)
    |> assign(:record, Record.get_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Record"m)
    |> assign(:record, %Record{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Listing Records"m)
    |> assign(:record, nil)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.RecordLive.FormComponent, {:saved, record}},
        socket
      ) do
    {:noreply, stream_insert(socket, :records, record)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    record = Record.get_by_id!(id)
    :ok = Record.destroy(record)

    {:noreply, stream_delete(socket, :records, record)}
  end

  @impl true
  def handle_event("toggle-filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end
end
