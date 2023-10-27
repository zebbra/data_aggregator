defmodule DataAggregatorWeb.RecordLive.Index do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Data.Record

  import DataAggregatorWeb.RecordLive.PreviewComponent
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
        page: pagination_options(current_page, current_limit)
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
      |> stream_insert(:records, record |> Map.put(:selected, false))

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
      |> stream_delete(:records, record)

    {:noreply, stream_delete(socket, :records, record)}
  end

  @impl true
  def handle_event("sort:select", %{"sort" => sort}, socket) do
    socket = handle_sort(socket, sort)

    {:noreply,
     patch_params(socket, %{
       sort: socket.assigns.current_sort,
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
  def handle_event("select", %{"id" => id}, socket) do
    old_selected = socket.assigns.current_selected
    new_selected = Record.get_by_id!(id)

    if old_selected == new_selected do
      {:noreply, unselect_current_selected(socket)}
    else
      socket = assign(socket, :current_selected, new_selected)
      new_selected = Map.put(new_selected, :selected, true)

      if old_selected do
        old_selected = Map.put(old_selected, :selected, false)

        socket =
          socket
          |> stream_insert(:records, old_selected)
          |> stream_insert(:records, new_selected)

        {:noreply, socket}
      else
        {:noreply, stream_insert(socket, :records, new_selected)}
      end
    end
  end

  defp patch_params(socket, params) do
    params = Map.reject(params, &(elem(&1, 1) in ["", nil]))
    push_patch(socket, to: ~p"/records?#{params}", replace: true)
  end

  defp unselect_current_selected(socket) do
    selected = socket.assigns.current_selected

    if selected do
      selected = Map.put(selected, :selected, false)

      socket
      |> assign(:current_selected, nil)
      |> stream_insert(:records, selected)
    else
      socket
    end
  end
end
