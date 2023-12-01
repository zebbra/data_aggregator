defmodule DataAggregatorWeb.Components.Internal.Pagination do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  # Assign the current page from URL params to the socket
  def assign_current_page(socket, params) do
    page =
      case params do
        %{"page" => page} -> String.to_integer(page)
        _ -> nil
      end

    assign(socket, :current_page, page)
  end

  # Assign the current limit from URL params to the socket
  def assign_current_limit(socket, params, default_limit) do
    limit =
      case params do
        %{"limit" => limit} -> String.to_integer(limit)
        _ -> default_limit
      end

    assign(socket, :current_limit, limit)
  end

  # Extract pagination option from params on initial load
  def pagination_options(page, limit) when page > 0 and is_integer(page) do
    offset = (page - 1) * limit
    [count: true, offset: offset, limit: limit]
  end

  def pagination_options(_, limit) do
    [count: true, limit: limit]
  end

  # Extract from and to values from page_meta
  def paginate_page_meta(page_meta) do
    from = page_meta.offset + 1

    to =
      if page_meta.offset + page_meta.limit > page_meta.count do
        page_meta.count
      else
        page_meta.offset + page_meta.limit
      end

    [from, to]
  end

  # Handle a previous page event from the client
  def handle_prev_page(socket) do
    %{current_page: current_page} = socket.assigns

    prev_page = if is_nil(current_page) || current_page <= 1, do: 1, else: current_page - 1

    socket
    |> assign(:current_page, prev_page)
    |> assign(:current_selected, nil)
  end

  # Handle a next page event from the client
  def handle_next_page(socket) do
    %{current_page: current_page} = socket.assigns

    next_page = if is_nil(current_page) || current_page <= 1, do: 2, else: current_page + 1

    socket
    |> assign(:current_page, next_page)
    |> assign(:current_selected, nil)
  end

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Components.Internal.Pagination

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
    end
  end
end
