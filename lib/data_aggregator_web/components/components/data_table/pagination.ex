defmodule DataAggregatorWeb.Components.Pagination do
  @moduledoc """
  This component is used to render a pagination component.
  """

  use Phoenix.Component

  @doc ~S"""
    Renders a pagination component.
  """
  attr(:meta, :map, default: %{}, doc: "the metadata for the pagination")
  attr(:class, :string, default: nil, doc: "the classe for the pagination")
  attr(:path, :string, required: true, doc: "the base path of the current view")
  attr(:params, :map, default: %{}, doc: "the query params for the current view")

  def pagination(assigns) do
    ~H"""
    <div class="mx-8 mt-3 hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
      <div>
        <p class="text-base-content text-sm">
          Showing <span class="font-medium"><%= offset(@params) + 1 %></span>
          to
          <span class="font-medium"><%= min(offset(@params) + limit(@params), @meta.count) %></span>
          of <span class="font-medium"><%= @meta.count %></span>
          results
        </p>
      </div>
      <div>
        <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
          <a
            href={pagination_path_helper(:prev, @params, @path)}
            class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
          >
            <span class="sr-only">Previous</span>
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path
                fill-rule="evenodd"
                d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z"
                clip-rule="evenodd"
              />
            </svg>
          </a>
          <div :for={position <- 1..min(total_pages(@meta), 7)}>
            <%= pagination_navigation_element(assigns, position) %>
          </div>
          <a
            href={pagination_path_helper(:next, @params, @path)}
            class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
          >
            <span class="sr-only">Next</span>
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path
                fill-rule="evenodd"
                d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                clip-rule="evenodd"
              />
            </svg>
          </a>
        </nav>
      </div>
    </div>
    """
  end

  def filters_map_from_params(%{"filter" => filter} = _params) do
    filter
    |> Enum.flat_map(fn {outer_key, inner_map} ->
      Enum.map(inner_map, fn {inner_key, value} ->
        {"filter[#{outer_key}][#{inner_key}]", value}
      end)
    end)
    |> Map.new()
  end

  def filters_map_from_params(_params), do: %{}

  def default_limit, do: DataAggregator.Records.Record.default_limit()

  def page_query_from_params(%{"limit" => limit, "offset" => offset}) do
    %{limit: String.to_integer(limit), offset: String.to_integer(offset)}
  end

  def page_query_from_params(%{"limit" => limit}) do
    %{limit: String.to_integer(limit), offset: 0}
  end

  def page_query_from_params(%{"offset" => offset}) do
    %{offset: String.to_integer(offset)}
  end

  def page_query_from_params(_params) do
    %{offset: 0}
  end

  def query_from_params(params) do
    params
    |> page_query_from_params()
    |> Map.merge(filters_map_from_params(params))
    |> Map.put(:sort, params["sort"])
  end

  def limit(params) do
    case params["limit"] do
      nil -> default_limit()
      limit -> String.to_integer(limit)
    end
  end

  def offset(params) do
    case params["offset"] do
      nil -> 0
      offset -> String.to_integer(offset)
    end
  end

  def pagination_path_helper(:next, params, path) do
    query = query_from_params(params)
    query = Map.update(query, :offset, limit(params), &(&1 + limit(params)))

    "#{path}?#{URI.encode_query(query)}"
  end

  def pagination_path_helper(:prev, params, path) do
    query = query_from_params(params)
    query = Map.update(query, :offset, 1, &(&1 - limit(params)))

    "#{path}?#{URI.encode_query(query)}"
  end

  def pagination_path_helper(number, params, path) when is_integer(number) do
    query = query_from_params(params)
    query = Map.put(query, :offset, limit(params) * (number - 1))

    "#{path}?#{URI.encode_query(query)}"
  end

  def total_pages(meta) do
    ceil(meta.count / meta.limit)
    # div(meta.count, meta.limit)
  end

  def current_page(meta) do
    div(meta.offset, meta.limit) + 1
  end

  def render_element(assigns, page_number, false = _is_ellipsis) do
    assigns = assign(assigns, page_number: page_number)

    ~H"""
    <a
      href={pagination_path_helper(@page_number, @params, @path)}
      class={[
        "text-base-content relative inline-flex items-center px-4 py-2 text-sm font-semibold ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0",
        active_page(assigns)
      ]}
    >
      <%= @page_number %>
    </a>
    """
  end

  def render_element(assigns, _page_number, true = _is_ellipsis) do
    ~H"""
    <span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0">
      ...
    </span>
    """
  end

  def active_page(assigns) do
    if current_page(assigns.meta) == assigns.page_number do
      "bg-primary"
    else
      ""
    end
  end

  def pagination_navigation_element(assigns, 1) do
    render_element(assigns, 1, false)
  end

  def pagination_navigation_element(assigns, 2) do
    render_element(assigns, 2, current_page(assigns.meta) > 4 && total_pages(assigns.meta) > 7)
  end

  def pagination_navigation_element(assigns, 3) do
    current_page = current_page(assigns.meta)

    page =
      cond do
        current_page < 5 || total_pages(assigns.meta) < 8 -> 3
        total_pages(assigns.meta) - current_page < 4 -> total_pages(assigns.meta) - 4
        true -> current_page - 1
      end

    render_element(assigns, page, false)
  end

  def pagination_navigation_element(assigns, 4) do
    current_page = current_page(assigns.meta)

    page =
      cond do
        current_page < 5 || total_pages(assigns.meta) < 8 -> 4
        total_pages(assigns.meta) - current_page < 4 -> total_pages(assigns.meta) - 3
        true -> current_page
      end

    render_element(assigns, page, false)
  end

  def pagination_navigation_element(assigns, 5) do
    current_page = current_page(assigns.meta)

    page =
      cond do
        current_page < 5 || total_pages(assigns.meta) < 8 -> 5
        total_pages(assigns.meta) - current_page < 4 -> total_pages(assigns.meta) - 2
        true -> current_page + 1
      end

    render_element(assigns, page, false)
  end

  def pagination_navigation_element(assigns, 6) do
    page =
      if total_pages(assigns.meta) < 8 do
        6
      else
        total_pages(assigns.meta) - 1
      end

    render_element(
      assigns,
      page,
      total_pages(assigns.meta) - current_page(assigns.meta) > 3 && total_pages(assigns.meta) > 7
    )
  end

  def pagination_navigation_element(assigns, 7) do
    render_element(assigns, total_pages(assigns.meta), false)
  end
end
