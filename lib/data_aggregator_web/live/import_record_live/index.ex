defmodule DataAggregatorWeb.ImportRecordLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.ImportRecord

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
      |> assign_current_page(params)
      |> assign_current_limit(params, ImportRecord.default_limit())
      |> assign_current_path_params(params)
      |> assign(:show_filters, false)
      |> assign_import_records()

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp assign_import_records(socket) do
    list_import_records(socket)
  end

  defp list_import_records(socket) do
    %{current_sort: current_sort, current_page: current_page, current_limit: current_limit} =
      socket.assigns

    page =
      ImportRecord.read!(%{sort: current_sort},
        page: pagination_options(current_page, current_limit)
      )

    stream_page(socket, page)
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
  def handle_event("sort:select", %{"sort" => sort}, socket) do
    {:noreply,
     patch_params(socket, %{
       "sort" => handle_sort(socket, sort),
       limit: socket.assigns.current_limit
     })}
  end

  @impl true
  def handle_event("page:prev", _params, socket) do
    socket = handle_prev_page(socket)

    {:noreply,
     patch_params(socket, %{
       sort: socket.assigns.current_sort,
       page: socket.assigns.current_page,
       limit: socket.assigns.current_limit
     })}
  end

  @impl true
  def handle_event("page:next", _params, socket) do
    socket = handle_next_page(socket)

    {:noreply,
     patch_params(socket, %{
       sort: socket.assigns.current_sort,
       page: socket.assigns.current_page,
       limit: socket.assigns.current_limit
     })}
  end

  @impl true
  def handle_event("page:change", %{"limit" => limit}, socket) do
    {:noreply,
     patch_params(socket, %{
       sort: socket.assigns.current_sort,
       page: 1,
       limit: String.to_integer(limit)
     })}
  end

  @impl true
  def handle_event("toggle-filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  defp patch_params(socket, params) do
    params = Map.reject(params, &(elem(&1, 1) in ["", nil]))
    push_patch(socket, to: ~p"/import_records?#{params}", replace: true)
  end
end
