defmodule DataAggregatorWeb.Components.DataTable do
  @moduledoc """
  This component is used to render a table of data.
  """
  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Components.Pagination, only: [pagination: 1]
  import DataAggregatorWeb.Gettext

  @doc ~S"""
    Renders a table with filter, sort and pagination.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:class, :string, default: nil, doc: "the class for the table")
  attr(:rows, :list, required: true, doc: "the list of rows to render")
  attr(:meta, :map, default: %{}, doc: "the metadata for the table")
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")
  attr(:path, :string, required: true, doc: "the base path of the current view")
  attr(:params, :map, default: %{}, doc: "the query params for the current view")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string, doc: "the label for the column")
    attr(:class, :string, doc: "the class for the column")
    attr(:key, :atom, doc: "the key for the column")
  end

  slot :action, doc: "the slot for showing user actions in the last table column" do
    attr(:class, :string, doc: "the class for the action")
  end

  def data_table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table role="table" class={["text-base-content table", @class]}>
      <thead role="rowgroup">
        <tr role="row" class="border-base-content/10">
          <th
            :for={col <- @col}
            role="columnheader"
            scope="col"
            class={["first:pl-6 last:pr-6 lg:first:pl-8 lg:last:pr-8", col[:class]]}
          >
            <%!-- <%= col[:label] %>
            <.icon name="hero-arrow-path" class="text-base-content/50" /> --%>
            <%= render_column_header(assigns, col) %>
          </th>
          <th :if={@action != []} role="columnheader" scope="col" class="pr-8 lg:pr-10">
            <span class="sr-only"><%= ~t"Actions"m %></span>
          </th>
        </tr>
      </thead>
      <tbody
        id={@id}
        role="rowgroup"
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
      >
        <tr
          :for={row <- @rows}
          id={@row_id && @row_id.(row)}
          role="rowgroup"
          class={[@row_click && @row_click.(row) && "hover", "border-base-content/10"]}
        >
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            role="cell"
            class={["first:pl-6 last:pr-6 lg:first:pl-8 lg:last:pr-8", col[:class]]}
          >
            <%= render_slot(col, @row_item.(row)) %>
          </td>
          <td :if={@action != []} role="cell" class="whitespace-nowrap pr-8 text-right lg:pr-10">
            <span :for={action <- @action} class={action[:class]}>
              <%= render_slot(action, @row_item.(row)) %>
            </span>
          </td>
        </tr>
      </tbody>
    </table>
    <.pagination meta={@meta} path={@path} params={@params} class="mt-4 my-8" />
    """
  end

  def render_column_header(assigns, col) do
    assigns = assign(assigns, :col, col)
    assigns = assign(assigns, :current_sort, List.first(assigns.meta.rerun.sort))

    maybe_render_link(assigns)

    # 2 cases: either the column is the current sort, or it's not
  end

  def maybe_render_link(%{col: %{key: col_key}, current_sort: {current_sort_key, _}} = assigns)
      when col_key == current_sort_key do
    ~H"""
    <.link
      patch={sort_path_helper(@col[:key], @current_sort, @path, @params)}
      class="grow inline-flex"
    >
      <div class="my-auto mr-2">
        <%= @col[:label] %>
      </div>
      <.icon name={sort_icon(@col[:key], @meta)} class="text-base-content/50" />
    </.link>
    """
  end

  def maybe_render_link(assigns) do
    ~H"""
    <.link
      patch={sort_path_helper(@col[:key], @current_sort, @path, @params)}
      class="grow inline-flex group"
    >
      <div class="my-auto mr-2">
        <%= @col[:label] %>
      </div>
      <.icon
        name={sort_icon(@col[:key], @meta)}
        class="text-base-content/50 opacity-0 group-hover:opacity-100"
      />
    </.link>
    """
  end

  def sort_icon(key, meta) do
    case List.first(meta.rerun.sort) do
      nil -> "hero-"
      {^key, :asc} -> "hero-chevron-up"
      {^key, :desc} -> "hero-chevron-down"
      {_, _} -> "hero-chevron-up"
    end
  end

  def sort_path_helper(col_key, current_sort, path, params) do
    query_params =
      params
      |> page_params()
      |> filter_params(params)
      |> sort_params(current_sort, col_key)

    "/#{path}?#{Plug.Conn.Query.encode(query_params)}"
  end

  def page_params(%{"limit" => limit}) do
    %{"limit" => limit}
  end

  def page_params(_params), do: %{}

  def filter_params(query_params, %{"filter" => filter}) do
    Map.merge(%{"filter" => filter}, query_params)
  end

  def filter_params(query_params, _params), do: query_params

  def sort_params(query_params, current_sort, col_key) when elem(current_sort, 0) == col_key do
    sort_value =
      case elem(current_sort, 1) do
        :asc -> "-#{elem(current_sort, 0)}"
        :desc -> "#{elem(current_sort, 0)}"
        # default to asc
        _ -> "#{elem(current_sort, 0)}"
      end

    Map.put(query_params, "sort", sort_value)
  end

  def sort_params(query_params, _current_sort, col_key) do
    Map.put(query_params, "sort", col_key)
  end

  def read_opts(starting_query, params) do
    []
    |> put_query_opt(starting_query, params)
    |> put_page_opt(params)
  end

  def put_query_opt(opts \\ [], starting_query, params) do
    query = query(starting_query, params)
    Keyword.put(opts, :query, query)
  end

  def put_page_opt(opts, params) do
    # page = [{:count, true} | page(params)]
    page = page(params)
    Keyword.put(opts, :page, page)
  end

  defp page(params) do
    put_opt = fn
      {"limit", limit}, opts -> Keyword.put(opts, :limit, String.to_integer(limit))
      {"offset", offset}, opts -> Keyword.put(opts, :offset, String.to_integer(offset))
      _, opts -> opts
    end

    Enum.reduce(params, [], put_opt)
  end

  def query(starting_query, params) do
    starting_query
    |> Ash.Query.to_query()
    |> filter_by(params)
    |> order_by(params)
  end

  defp filter_by(query, params)

  defp filter_by(query, %{"filter" => filter}) do
    Ash.Query.filter_input(query, filter)
  end

  defp filter_by(query, _params), do: query

  def order_by(%Ash.Query{resource: resource} = query, %{"sort" => sort}) do
    case Ash.Sort.parse_input(resource, sort) do
      {:ok, sorts} -> Ash.Query.sort(query, sorts)
      {:error, _} -> query
    end
  end

  def order_by(query, _params), do: query
end
