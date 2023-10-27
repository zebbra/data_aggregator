defmodule DataAggregatorWeb.QueryBuilder do
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [stream: 4]

  # Assign the current path params to the socket
  def assign_current_path_params(
        socket,
        params,
        allowed_keys \\ ["filter", "sort", "page", "limit"]
      ) do
    path_params =
      params
      |> Map.take(allowed_keys)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.new()

    assign(socket, :current_path_params, path_params)
  end

  # Assign the current sort from URL params to the socket
  def assign_current_sort(socket, params) do
    sort =
      case params do
        %{"sort" => sort} -> sort
        _ -> ""
      end

    validate_sort_field(sort)

    socket
    |> assign(:current_sort, sort)
  end

  # Extract the sort field from current_sort
  def current_sort_field(current_sort) when is_nil(current_sort), do: ""

  def current_sort_field(current_sort) do
    current_sort
    |> String.replace("-", "")
  end

  # Extract the sort direction from current_sort
  def current_sort_dir(current_sort) when is_nil(current_sort), do: "asc"

  def current_sort_dir(current_sort) do
    if current_sort |> String.starts_with?("-") do
      "desc"
    else
      "asc"
    end
  end

  # Handle a sort event from the client
  def handle_sort(socket, sort) do
    %{current_sort: current_sort} = socket.assigns

    sort =
      case current_sort do
        # toggle desc -> asc
        "-" <> ^sort -> sort
        # toggle asc -> desc
        ^sort -> "-" <> sort
        # default to desc for new sort
        _ -> "-" <> sort
      end

    socket
    |> assign(:current_sort, sort)
    |> assign(:current_selected, nil)
  end

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

  # Ensure the current selected record exists in the socket assigns
  def assign_current_selected(socket) do
    socket
    |> assign(:current_selected, Map.get(socket.assigns, :current_selected, nil))
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

  def stream_page(socket, page) do
    # For some reason, the results are appended to the stream in reverse order
    # if the stream does alredy exist. So we reverse the results in this case.
    results = if stream_exists?(socket), do: Enum.reverse(page.results), else: page.results
    page = Map.put(page, :results, [])

    results =
      Enum.map(results, fn result ->
        Map.put(
          result,
          :selected,
          socket.assigns.current_selected && result.id == socket.assigns.current_selected.id
        )
      end)

    socket
    |> assign(:page_meta, page)
    |> stream(:records, results, reset: true, at: 0, limit: 0)
  end

  # Helper function to check if a stream exists
  defp stream_exists?(socket) do
    socket.assigns[:streams] != nil
  end

  # Prevent random atoms from being created from user input
  defp validate_sort_field(sort) do
    sort
    |> String.replace("-", "")
    |> String.to_existing_atom()
  end
end
