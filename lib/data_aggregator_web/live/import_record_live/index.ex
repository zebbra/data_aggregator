defmodule DataAggregatorWeb.ImportRecordLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.ImportRecord

  @sort_options [:inserted_at, :updated_at, :unique_qualifier]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    import_records =
      ImportRecord.read!(Map.get(params, "order_by", ""))

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
      |> stream(:import_records, import_records)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Import Record"m)
    |> assign(:import_record, ImportRecord.get_by_id!(id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Import Record"m)
    |> assign(:import_record, ImportRecord.get_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Import Record"m)
    |> assign(:import_record, %ImportRecord{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Listing Import Records"m)
    |> assign(:import_record, nil)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.ImportRecordLive.FormComponent, {:saved, import_record}},
        socket
      ) do
    {:noreply, stream_insert(socket, :import_records, import_record)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    import_record = ImportRecord.get_by_id!(id)
    :ok = ImportRecord.destroy(import_record)

    {:noreply, stream_delete(socket, :import_records, import_record)}
  end

  @impl true
  def handle_event("toggle-filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end
end
