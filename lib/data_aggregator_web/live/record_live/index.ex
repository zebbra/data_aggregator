defmodule DataAggregatorWeb.RecordLive.Index do
  use DataAggregatorWeb, :live_view

  use DataAggregatorWeb.Components.Internal.Pagination
  use DataAggregatorWeb.Components.Internal.Sort

  alias DataAggregator.Records.Record

  import DataAggregatorWeb.RecordLive.PreviewComponent

  import DataAggregatorWeb.Components.Internal.{
    Path,
    Selection,
    Stream
  }

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
      |> assign_current_limit(params, Record.default_limit())
      |> assign_current_selected()
      |> assign_current_path_params(params)
      |> assign_records()

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp assign_records(socket) do
    list_records(socket)
  end

  defp list_records(socket) do
    %{current_sort: current_sort, current_page: current_page, current_limit: current_limit} =
      socket.assigns

    page =
      Record.read!(%{sort: current_sort},
        page: pagination_options(current_page, current_limit),
        load: :collection
      )

    stream_page(socket, page)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Record"m)
    |> assign(:current_selected, nil)
    |> assign(:record, Record.get_by_id!(id) |> Map.put(:selected, false))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Record"m)
    |> assign(:current_selected, nil)
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
    socket =
      socket
      |> stream_insert(:results, record |> Map.put(:selected, false))

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    record = Record.get_by_id!(id)
    :ok = Record.destroy(record)

    %{current_selected: current_selected} = socket.assigns

    new_selected =
      if current_selected && current_selected.id == id, do: nil, else: current_selected

    socket =
      socket
      |> assign(:current_selected, new_selected)
      |> stream_delete(:results, record)

    {:noreply, stream_delete(socket, :results, record)}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    new_selected = DataAggregator.Records.load!(Record.get_by_id!(id), [:collection])
    handle_select(socket, new_selected)
  end

  defp patch_params(socket, params) do
    params = Map.reject(params, &(elem(&1, 1) in ["", nil]))
    push_patch(socket, to: ~p"/records?#{params}", replace: true)
  end
end
