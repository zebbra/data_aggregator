defmodule DataAggregatorWeb.ImportRecordLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.ImportRecord

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_time, DateTime.utc_now())
      |> stream(:import_records, ImportRecord.read!())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Import Record")
    |> assign(:import_record, ImportRecord.get_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Import Record")
    |> assign(:import_record, %ImportRecord{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Import Records")
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
end
