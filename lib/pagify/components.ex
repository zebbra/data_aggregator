defmodule Pagify.Components do
  @moduledoc """
  Phoenix components for pagination, sortable tables and filter forms with
  `Pagify`.

  ## Introduction

  Please refere to the _Usage_ section in `Pagify` for more information.

  ## Customization

  The default classes, attributes, texts and symbols can be overridden by
  passing the `opts` assign. Since you probably will use the same `opts` in all
  your templates, you can globally configure an `opts` provider function for
  each component.

  The functions have to return the options as a keyword list. The overrides
  are deep-merged into the default options.

      defmodule MyAppWeb.CoreComponents do
        use Phoenix.Component

        def pagination_opts do
           [
            ellipsis_attrs: [class: "ellipsis"],
            ellipsis_content: "‥",
            next_link_attrs: [class: "next"],
            next_link_content: next_icon(),
            page_links: {:ellipsis, 7},
            pagination_link_aria_label: &"\#{&1}ページ目へ",
            previous_link_attrs: [class: "prev"],
            previous_link_content: previous_icon()
          ]
        end

        defp next_icon do
          assigns = %{}

          ~H\"""
          <i class="fas fa-chevron-right"/>
          \"""
        end

        defp previous_icon do
          assigns = %{}

          ~H\"""
          <i class="fas fa-chevron-left"/>
          \"""
        end

        def table_opts do
          [
            container: true,
            container_attrs: [class: "table-container"],
            no_results_content: no_results_content(),
            table_attrs: [class: "table"]
          ]
        end

        defp no_results_content do
          assigns = %{}

          ~H\"""
          <p>Nothing found.</p>
          \"""
        end
      end

  Refer to `t:pagination_option/0` and `t:table_option/0` for a list of
  available options and defaults.

  Once you have defined these functions, you can reference them with a
  module/function tuple in `config/config.exs`.

  ```elixir
  config :my_app :pagify_phoenix,
    pagination: [opts: {MyAppWeb.CoreComponents, :pagination_opts}],
    table: [opts: {MyAppWeb.CoreComponents, :table_opts}]
  ```

  ## Hiding default parameters

  Default values for pagination and ordering are omitted from the query
  parameters. Pagify.Components function will pick up the default values
  from the `Ash.Resource` specifications.

  ## Links

  Links are generated with `Phoenix.Component.link/1`. This will
  lead to `<a>` tags with `data-phx-link` and `data-phx-link-state` attributes,
  which will be ignored outside of LiveViews and LiveComponents.

  When used within a LiveView or LiveComponent, you will need to handle the new
  params in the `c:Phoenix.LiveView.handle_params/3` callback of your LiveView
  module.

  ## Using JS commands

  You can pass a `Phoenix.LiveView.JS` command as `on_paginate` and `on_sort`
  attributes.

  If used with the `path` attribute, the URL will be patched _and_ the given
  JS command will be executed.

  If used without the `path` attribute, you will need to include a `push`
  command to trigger an event when a pagination or sort link is clicked.

  You can set a different target by assigning a `:target`. The value
  will be used as the `phx-target` attribute.

      <Pagify.Components.table
        items={@items}
        meta={@meta}
        on_sort={JS.push("sort-posts")}
        target={@myself}
      />

      <Pagify.Components.pagination
        meta={@meta}
        on_paginate={JS.push("paginate-posts")}
        target={@myself}
      />

  You will need to handle the event in the `c:Phoenix.LiveView.handle_event/3`
  or `c:Phoenix.LiveComponent.handle_event/3` callback of your
  LiveView or LiveComponent module. The event name will be the one you set with
  the `:event` option.

      def handle_event("paginate-posts", %{"offset" => offset}, socket) do
        pagify = Pagify.set_offset(socket.assigns.meta.pagify, offset)

        with {:ok, {posts, meta}} <- Post.list_posts(pagify) do
          {:noreply, assign(socket, posts: posts, meta: meta)}
        end
      end

      def handle_event("sort-posts", %{"order" => order}, socket) do
        pagify = Pagify.push_order(socket.assigns.meta.pagify, order)

        with {:ok, {posts, meta}} <- Post.list_posts(pagify) do
          {:noreply, assign(socket, posts: posts, meta: meta)}
        end
      end
  """

  use Phoenix.Component

  alias Pagify.Components.Misc
  alias Pagify.Components.Pagination
  alias Pagify.Components.Table
  alias Pagify.Meta
  alias Phoenix.LiveView.JS
  alias Plug.Conn.Query

  @typedoc """
  Defines the available options for `Pagify.Components.pagination/1`.

  - `:current_link_attrs` - The attributes for the link to the current page.
    Default: `#{inspect(Pagination.default_opts()[:current_link_attrs])}`.
  - `:disabled_class` - The class which is added to disabled links. Default:
    `#{inspect(Pagination.default_opts()[:disabled_class])}`.
  - `:ellipsis_attrs` - The attributes for the `<span>` that wraps the
    ellipsis.
    Default: `#{inspect(Pagination.default_opts()[:ellipsis_attrs])}`.
  - `:ellipsis_content` - The content for the ellipsis element.
    Default: `#{inspect(Pagination.default_opts()[:ellipsis_content])}`.
  - `:next_link_attrs` - The attributes for the link to the next page.
    Default: `#{inspect(Pagination.default_opts()[:next_link_attrs])}`.
  - `:next_link_content` - The content for the link to the next page.
    Default: `#{inspect(Pagination.default_opts()[:next_link_content])}`.
  - `:page_links` - Specifies how many page links should be rendered.
    Default: `#{inspect(Pagination.default_opts()[:page_links])}`.
    - `:all` - Renders all page links.
    - `{:ellipsis, n}` - Renders `n` page links. Renders ellipsis elements if
      there are more pages than displayed.
    - `:hide` - Does not render any page links.
  - `:pagination_link_aria_label` - 1-arity function that takes a page number
    and returns an aria label for the corresponding page link.
    Default: `&"Go to page \#{&1}"`.
  - `:pagination_link_attrs` - The attributes for the pagination links.
    Default: `#{inspect(Pagination.default_opts()[:pagination_link_attrs])}`.
  - `:previous_link_attrs` - The attributes for the link to the previous page.
    Default: `#{inspect(Pagination.default_opts()[:previous_link_attrs])}`.
  - `:previous_link_content` - The content for the link to the previous page.
    Default: `#{inspect(Pagination.default_opts()[:previous_link_content])}`.
  - `:wrapper_attrs` - The attributes for the `<nav>` element that wraps the
    pagination links.
    Default: `#{inspect(Pagination.default_opts()[:wrapper_attrs])}`.
  """
  @type pagination_option ::
          {:current_link_attrs, keyword}
          | {:disabled_class, String.t()}
          | {:ellipsis_attrs, keyword}
          | {:ellipsis_content, Phoenix.HTML.safe() | binary}
          | {:next_link_attrs, keyword}
          | {:next_link_content, Phoenix.HTML.safe() | binary}
          | {:page_links, :all | :hide | {:ellipsis, pos_integer}}
          | {:pagination_link_aria_label, (pos_integer -> binary)}
          | {:pagination_link_attrs, keyword}
          | {:previous_link_attrs, keyword}
          | {:previous_link_content, Phoenix.HTML.safe() | binary}
          | {:wrapper_attrs, keyword}

  @typedoc """
  Defines the available types for the `path` attribute of `Pagify.Components.pagination/1`.
  """
  @type pagination_path ::
          String.t()
          | {module(), atom(), [any()]}
          | {function, [any]}
          | (keyword -> String.t())

  @typedoc """
  Defines the available options for `Pagify.Components.table/1`.

  - `:container` - Wraps the table in a `<div>` if `true`.
    Default: `#{inspect(Table.default_opts()[:container])}`.
  - `:container_attrs` - The attributes for the table container.
    Default: `#{inspect(Table.default_opts()[:container_attrs])}`.
  - `:no_results_content` - Any content that should be rendered if there are no
    results. Default: `<p>No results.</p>`.
  - `:table_attrs` - The attributes for the `<table>` element.
    Default: `#{inspect(Table.default_opts()[:table_attrs])}`.
  - `:th_wrapper_attrs` - The attributes for the `<span>` element that wraps the
    header link and the order direction symbol.
    Default: `#{inspect(Table.default_opts()[:th_wrapper_attrs])}`.
  - `:symbol_asc` - The symbol that is used to indicate that the column is
    sorted in ascending order.
    Default: `#{inspect(Table.default_opts()[:symbol_asc])}`.
  - `:symbol_attrs` - The attributes for the `<span>` element that wraps the
    order direction indicator in the header columns.
    Default: `#{inspect(Table.default_opts()[:symbol_attrs])}`.
  - `:symbol_desc` - The symbol that is used to indicate that the column is
    sorted in ascending order.
    Default: `#{inspect(Table.default_opts()[:symbol_desc])}`.
  - `:symbol_unsorted` - The symbol that is used to indicate that the column is
    not sorted. Default: `#{inspect(Table.default_opts()[:symbol_unsorted])}`.
  - `:tbody_attrs`: Attributes to be added to the `<tbody>` tag within the
    `<table>`. Default: `#{inspect(Table.default_opts()[:tbody_attrs])}`.
  - `:tbody_td_attrs`: Attributes to be added to each `<td>` tag within the
    `<tbody>`. Default: `#{inspect(Table.default_opts()[:tbody_td_attrs])}`.
  - `:thead_attrs`: Attributes to be added to the `<thead>` tag within the
    `<table>`. Default: `#{inspect(Table.default_opts()[:thead_attrs])}`.
  - `:tbody_tr_attrs`: Attributes to be added to each `<tr>` tag within the
    `<tbody>`. A function with arity of 1 may be passed to dynamically generate
    the attrs based on row data.
    Default: `#{inspect(Table.default_opts()[:tbody_tr_attrs])}`.
  - `:thead_th_attrs`: Attributes to be added to each `<th>` tag within the
    `<thead>`. Default: `#{inspect(Table.default_opts()[:thead_th_attrs])}`.
  - `:thead_tr_attrs`: Attributes to be added to each `<tr>` tag within the
    `<thead>`. Default: `#{inspect(Table.default_opts()[:thead_tr_attrs])}`.
  - `:limit_order_by` - Limit the number of applied order_by fields.
    Default: `#{inspect(Table.default_opts()[:limit_order_by])}`.
  """
  @type table_option ::
          {:container, boolean}
          | {:container_attrs, keyword}
          | {:no_results_content, Phoenix.HTML.safe() | binary}
          | {:symbol_asc, Phoenix.HTML.safe() | binary}
          | {:symbol_attrs, keyword}
          | {:symbol_desc, Phoenix.HTML.safe() | binary}
          | {:symbol_unsorted, Phoenix.HTML.safe() | binary}
          | {:table_attrs, keyword}
          | {:tbody_attrs, keyword}
          | {:thead_attrs, keyword}
          | {:tbody_td_attrs, keyword}
          | {:tbody_tr_attrs, keyword | (any -> keyword)}
          | {:th_wrapper_attrs, keyword}
          | {:thead_th_attrs, keyword}
          | {:thead_tr_attrs, keyword}
          | {:limit_order_by, pos_integer}

  @doc """
  Generates a pagination element.

  ## Examples

      <Pagify.Components.pagination
        meta={@meta}
        path={~p"/posts"}
      />

      <Pagify.Components.pagination
        meta={@meta}
        path={{Routes, :post_path, [@socket, :index]}}
      />

  ## Page link options

  By default, page links for all pages are shown. You can limit the number of
  page links or disable them altogether by passing the `:page_links` option.

  - `:all`: Show all page links.
  - `:hide`: Don't show any page links. Only the previous/next links will be
    shown.
  - `{:ellipsis, x}`: Limits the number of page links. The first and last page
    are always displayed. The `x` refers to the number of additional page links
    to show (default n=4).
  """
  @spec pagination(map()) :: Phoenix.LiveView.Rendered.t()

  attr :meta, Meta,
    required: true,
    doc: """
    The meta information of the query as returned by the `Pagify` query functions
    """

  attr :path, :any,
    default: nil,
    doc: """
    If set, the current view is patched with updated query parameters when a
    pagination link is clicked. In case the `on_paginate` attribute is set as
    well, the URL is patched _and_ the given command is executed.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `Pagify.Components.build_path/3` for details.
    """

  attr :on_paginate, JS,
    default: nil,
    doc: """
    A `Phoenix.LiveView.JS` command that is triggered when a pagination link is
    clicked.

    If used without the `path` attribute, you should include a `push` operation
    to handle the event with the `handle_event` callback.

        <.pagination
          meta={@meta}
          on_paginate={
            JS.dispatch("my_app:scroll_to", to: "#post-table") |> JS.push("paginate")
          }
        />

    If used with the `path` attribute, the URL is patched _and_ the given
    JS command is executed.

        <.pagination
          meta={@meta}
          path={~"/posts"}
          on_paginate={JS.dispatch("my_app:scroll_to", to: "#post-table")}
        />

    With the above attributes in place, you can add the following JavaScript to
    your application to scroll to the top of your table whenever a pagination
    link is clicked:

    ```js
    window.addEventListener("my_app:scroll_to", (e) => {
      e.target.scrollIntoView();
    });
    ```

    You can use CSS to scroll to the new position smoothly.

    ```css
    html {
      scroll-behavior: smooth;
    }
    ```
    """

  attr :target, :string,
    default: nil,
    doc: """
    Sets the `phx-target` attribute for the pagination links.
    """

  attr :opts, :list,
    default: [],
    doc: """
    Options to customize the pagination. See
    `t:Pagify.Components.pagination_option/0`. Note that the options passed to the
    function are deep merged into the default options. Since these options will
    likely be the same for all the tables in a project, it is recommended to
    define them once in a function or set them in a wrapper function as
    described in the `Customization` section of the module documentation.
    """

  def pagination(%{path: nil, on_paginate: nil}) do
    raise Pagify.Error.Components.PathOrJSError, component: :pagination
  end

  def pagination(%{meta: meta, opts: opts, path: path} = assigns) do
    assigns =
      assigns
      |> assign(:opts, Pagination.merge_opts(opts))
      |> assign(:page_link_helper, Pagination.build_page_link_helper(meta, path))
      |> assign(:path, nil)

    ~H"""
    <nav :if={Pagination.show_pagination?(@meta)} {@opts[:wrapper_attrs]}>
      <.pagination_link
        disabled={!@meta.has_previous_page?}
        disabled_class={@opts[:disabled_class]}
        target={@target}
        offset={@meta.previous_offset}
        path={@page_link_helper.(@meta.previous_offset)}
        on_paginate={@on_paginate}
        {@opts[:previous_link_attrs]}
      >
        <%= @opts[:previous_link_content] %>
      </.pagination_link>
      <.page_links
        :if={@opts[:page_links] != :hide}
        meta={@meta}
        on_paginate={@on_paginate}
        page_link_helper={@page_link_helper}
        opts={@opts}
        target={@target}
      />
      <.pagination_link
        disabled={!@meta.has_next_page?}
        disabled_class={@opts[:disabled_class]}
        target={@target}
        offset={@meta.next_offset}
        path={@page_link_helper.(@meta.next_offset)}
        on_paginate={@on_paginate}
        {@opts[:next_link_attrs]}
      >
        <%= @opts[:next_link_content] %>
      </.pagination_link>
    </nav>
    """
  end

  attr :meta, Meta, required: true
  attr :on_paginate, JS
  attr :page_link_helper, :any, required: true
  attr :target, :string, required: true
  attr :opts, :list, required: true

  defp page_links(%{meta: meta} = assigns) do
    max_pages =
      Pagination.max_pages(assigns.opts[:page_links], assigns.meta.total_pages)

    range =
      first..last =
      Pagination.get_page_link_range(
        meta.current_page,
        max_pages,
        meta.total_pages
      )

    assigns = assign(assigns, first: first, last: last, range: range)

    ~H"""
    <.pagination_link
      :if={@first > 1}
      target={@target}
      offset={0}
      path={@page_link_helper.(0)}
      on_paginate={@on_paginate}
      {Pagination.attrs_for_page_link(1, @meta, @opts)}
    >
      1
    </.pagination_link>

    <span :if={@first > 2} {@opts[:ellipsis_attrs]}><%= @opts[:ellipsis_content] %></span>

    <.pagination_link
      :for={page <- @range}
      target={@target}
      offset={page * @meta.current_limit - @meta.current_limit}
      path={@page_link_helper.(page * @meta.current_limit - @meta.current_limit)}
      on_paginate={@on_paginate}
      {Pagination.attrs_for_page_link(page, @meta, @opts)}
    >
      <%= page %>
    </.pagination_link>

    <span :if={@last < @meta.total_pages - 1} {@opts[:ellipsis_attrs]}>
      <%= @opts[:ellipsis_content] %>
    </span>

    <.pagination_link
      :if={@last < @meta.total_pages}
      target={@target}
      offset={@meta.total_pages * @meta.current_limit - @meta.current_limit}
      path={@page_link_helper.(@meta.total_pages * @meta.current_limit - @meta.current_limit)}
      on_paginate={@on_paginate}
      {Pagination.attrs_for_page_link(@meta.total_pages, @meta, @opts)}
    >
      <%= @meta.total_pages %>
    </.pagination_link>
    """
  end

  attr :path, :string
  attr :on_paginate, JS
  attr :target, :string, required: true
  attr :offset, :integer, required: true
  attr :disabled, :boolean, default: false
  attr :disabled_class, :string
  attr :rest, :global

  slot :inner_block

  defp pagination_link(%{disabled: true, disabled_class: disabled_class} = assigns) do
    rest =
      Map.update(assigns.rest, :class, disabled_class, fn class ->
        [class, disabled_class]
      end)

    assigns = assign(assigns, :rest, rest)

    ~H"""
    <span {@rest} class={@disabled_class}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp pagination_link(%{on_paginate: nil, path: path} = assigns) when is_binary(path) do
    ~H"""
    <.link patch={@path} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp pagination_link(%{} = assigns) do
    ~H"""
    <.link
      patch={@path}
      phx-click={@on_paginate}
      phx-target={@target}
      phx-value-offset={@offset}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Generates a table with sortable columns.

  ## Example

  ```elixir
  <Pagify.Components.table items={@posts} meta={@meta} path={~p"/posts"}>
    <:col :let={post} label="Name" field={:name}><%= post.name %></:col>
    <:col :let={post} label="Author" field={:author}><%= post.author %></:col>
  </Pagify.Components.table>
  ```
  """
  @spec table(map) :: Phoenix.LiveView.Rendered.t()

  attr :id, :string,
    doc: """
    ID used on the table. If not set, an ID is chosen based on the resource
    module derived from the `Pagify.Meta` struct.

    The ID is necessary in case the table is fed with a LiveView stream.
    """

  attr :items, :list,
    required: true,
    doc: """
    The list of items to be displayed in rows. This is the result list returned
    by the query.
    """

  attr :meta, Meta,
    default: nil,
    doc: "The `Pagify.Meta` struct returned by the query function. If omitted
    the table will be rendered without order_by links."

  attr :path, :any,
    default: nil,
    doc: """
    If set, the current view is patched with updated query parameters when a
    header link for sorting is clicked. In case the `on_sort` attribute is
    set as well, the URL is patched _and_ the given JS command is executed.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `Pagify.Components.build_path/3` for details.
    """

  attr :on_sort, JS,
    default: nil,
    doc: """
    A `Phoenix.LiveView.JS` command that is triggered when a header link for
    sorting is clicked.

    If used without the `path` attribute, you should include a `push` operation
    to handle the event with the `handle_event` callback.

        <.table
          items={@items}
          meta={@meta}
          on_sort={
            JS.dispatch("my_app:scroll_to", to: "#post-table") |> JS.push("sort")
          }
        />

    If used with the `path` attribute, the URL is patched _and_ the given
    JS command is executed.

        <.table
          meta={@meta}
          path={~"/posts"}
          on_sort={JS.dispatch("my_app:scroll_to", to: "#post-table")}
        />
    """

  attr :target, :string,
    default: nil,
    doc: "Sets the `phx-target` attribute for the header links."

  attr :caption_text, :string,
    default: nil,
    doc: "Content for the `<caption>` element."

  attr :opts, :list,
    default: [],
    doc: """
    Keyword list with additional options (see `t:Pagify.Components.table_option/0`).
    Note that the options passed to the function are deep merged into the
    default options. Since these options will likely be the same for all
    the tables in a project, it is recommended to define them once in a
    function or set them in a wrapper function as described in the `Customization`
    section of the module documentation.
    """

  attr :row_id, :any,
    default: nil,
    doc: """
    Overrides the default function that retrieves the row ID from a stream item.
    """

  attr :row_click, JS,
    default: nil,
    doc: """
    Sets the `phx-click` function attribute for each row `td`. Expects to be a
    function that receives a row item as an argument. This does not add the
    `phx-click` attribute to the `action` slot.

    Example:

    ```elixir
    row_click={&JS.navigate(~p"/users/\#{&1}")}
    ```
    """

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: """
    This function is called on the row item before it is passed to the :col
    and :action slots.
    """

  slot :caption,
    doc: """
    The slot for the table caption. If set, the content of the slot is rendered
    as the content of the `<caption>` element.

    ```elixir
    <:caption>
      <h2>Posts</h2>
    </:caption>
    """

  slot :col,
    required: true,
    doc: """
    For each column to render, add one `<:col>` element.

    ```elixir
    <:col :let={post} label="Name" field={:name} col_style="width: 20%;">
      <%= post.name %>
    </:col>
    ```

    Any additional assigns will be added as attributes to the `<td>` elements.

    """ do
    attr :label, :any, doc: "The content for the header column."

    attr :field, :atom,
      doc: """
      The field name for sorting. If set and the field is configured as sortable
      in the resource, the column header will be clickable, allowing the user to
      sort by that column. If the field is not marked as sortable or if the
      `field` attribute is omitted or set to `nil` or `false`, the column header
      will not be clickable.
      """

    attr :directions, :any,
      doc: """
      An optional 2-element tuple used for custom ascending and descending sort
      behavior for the column, i.e. `{:asc_nils_last, :desc_nils_first}`
      """

    attr :col_style, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_style` assign is set as `style` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :col_class, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_class` assign is set as `class` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :class, :string,
      doc: """
      Additional classes to add to the `<th>` and `<td>` element. Will be merged with the
      `thead_attr_attrs` and `tbody_td_attrs` attributes.
      """

    attr :thead_th_attrs, :list,
      doc: """
      Additional attributes to pass to the `<th>` element as a static keyword
      list. Note that these attributes will override any conflicting
      `thead_th_attrs` that are set at the table level.
      """

    attr :th_wrapper_attrs, :list,
      doc: """
      Additional attributes for the `<span>` element that wraps the
      header link and the order direction symbol. Note that these attributes
      will override any conflicting `th_wrapper_attrs` that are set at the table
      level.
      """

    attr :tbody_td_attrs, :any,
      doc: """
      Additional attributes to pass to the `<td>` element. May be provided as a
      static keyword list, or as a 1-arity function to dynamically generate the
      list using row data. Note that these attributes will override any
      conflicting `tbody_td_attrs` that are set at the table level.
      """
  end

  slot :action,
    doc: """
    The slot for showing user actions in the last table column. These columns
    do not receive the `row_click` attribute.


    ```elixir
    <:action :let={user}>
      <.link navigate={~p"/users/\#{user}"}>Show</.link>
    </:action>
    ```
    """ do
    attr :label, :string, doc: "The content for the header column."

    attr :show, :boolean, doc: "Boolean value to conditionally show the column. Defaults to `true`."

    attr :hide, :boolean, doc: "Boolean value to conditionally hide the column. Defaults to `false`."

    attr :col_style, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_style` assign is set as `style` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :col_class, :string,
      doc: """
      If set, a `<colgroup>` element is rendered and the value of the
      `col_class` assign is set as `class` attribute for the `<col>` element of
      the respective column. You can set the `width`, `background`, `border`,
      and `visibility` of a column this way.
      """

    attr :class, :string,
      doc: """
      Additional classes to add to the `<th>` and `<td>` element. Will be merged with the
      `thead_attr_attrs` and `tbody_td_attrs` attributes.
      """

    attr :thead_th_attrs, :list,
      doc: """
      Any additional attributes to pass to the `<th>` as a keyword list.
      """

    attr :tbody_td_attrs, :any,
      doc: """
      Any additional attributes to pass to the `<td>`. Can be a keyword list or
      a function that takes the current row item as an argument and returns a
      keyword list.
      """
  end

  slot :foot,
    default: nil,
    doc: """
    You can optionally add a `foot`. The inner block will be rendered inside
    a `tfoot` element.

        <Pagify.Components.table>
          <:foot>
            <tr><td>Total: <span class="total"><%= @total %></span></td></tr>
          </:foot>
        </Pagify.Components.table>
    """

  def table(%{meta: %Meta{}, path: nil, on_sort: nil}) do
    raise Pagify.Error.Components.PathOrJSError, component: :table
  end

  def table(%{meta: nil} = assigns) do
    assigns =
      assigns
      |> assign(id: Map.get(assigns, :id, "table"))
      |> assign(meta: %Meta{})
      |> assign(on_sort: %JS{})

    table(assigns)
  end

  def table(%{meta: meta, opts: opts} = assigns) do
    assigns =
      assigns
      |> assign(:opts, Table.merge_opts(opts))
      |> assign_new(:id, fn -> table_id(meta.resource) end)

    ~H"""
    <%= if empty?(@items) do %>
      <%= @opts[:no_results_content] %>
    <% else %>
      <%= if @opts[:container] do %>
        <div id={@id <> "_container"} {@opts[:container_attrs]}>
          <Table.render
            caption_text={@caption_text}
            caption={@caption}
            col={@col}
            foot={@foot}
            on_sort={@on_sort}
            id={@id}
            items={@items}
            meta={@meta}
            opts={@opts}
            path={@path}
            target={@target}
            row_id={@row_id}
            row_click={@row_click}
            row_item={@row_item}
            action={@action}
          />
        </div>
      <% else %>
        <Table.render
          caption_text={@caption_text}
          caption={@caption}
          col={@col}
          foot={@foot}
          on_sort={@on_sort}
          id={@id}
          items={@items}
          meta={@meta}
          opts={@opts}
          path={@path}
          target={@target}
          row_id={@row_id}
          row_click={@row_click}
          row_item={@row_item}
          action={@action}
        />
      <% end %>
    <% end %>
    """
  end

  defp empty?(items)
  defp empty?([]), do: true
  defp empty?(%Phoenix.LiveView.LiveStream{inserts: [], deletes: []}), do: true
  defp empty?(_), do: false

  defp table_id(nil), do: "sortable_table"

  defp table_id(resource) do
    module_name = resource |> Module.split() |> List.last() |> Macro.underscore()
    module_name <> "_table"
  end

  @doc """
  Converts a Pagify struct into a keyword list that can be used as a query with
  Phoenix verified routes or route helper functions.

  ## Default parameters

  Default parameters for the limit and order parameters are omitted. The
  defaults are determined by calling `Pagify.get_option/3`.

  - Pass the `:for` option to pick up the default values from an `Ash.Resource`.
  - If the `Ash.Resource` has no default options set, the function will fall
    back to the application environment.

  ## Encoding queries

  To encode the returned query as a string, you will need to use
  `Plug.Conn.Query.encode/1`. `URI.encode_query/1` does not support bracket
  notation for arrays and maps.

  ## Date and time filters

  If you use the result of this function directly with
  `Phoenix.VerifiedRoutes.sigil_p/2` for verified routes or in a route helper
  function, all cast filter values need to be able to be converted to a string
  using the `Phoenix.Param` protocol.

  This protocol is implemented by default for integers, binaries, atoms, and
  structs. For structs, Phoenix's default behavior is to fetch the id field.

  If you have filters with `Date`, `DateTime`, `NaiveDateTime`,
  `Time` values, or any other custom structs (e.g. structs that represent
  composite types like a range column), you will need to implement the protocol
  for these specific structs in your application.

      defimpl Phoenix.Param, for: Date do
        def to_param(%Date{} = d), do: to_string(d)
      end

      defimpl Phoenix.Param, for: DateTime do
        def to_param(%DateTime{} = dt), do: to_string(dt)
      end

      defimpl Phoenix.Param, for: NaiveDateTime do
        def to_param(%NaiveDateTime{} = dt), do: to_string(dt)
      end

      defimpl Phoenix.Param, for: Time do
        def to_param(%Time{} = t), do: to_string(t)
      end

  ## Examples

      iex> to_query(%Pagify{})
      []

      iex> f = %Pagify{offset: 40, limit: 20}
      iex> to_query(f)
      [limit: 20, offset: 40]

      iex> f = %Pagify{offset: 40, limit: 20}
      iex> to_query(f, default_limit: 20)
      [offset: 40]

      iex> f = %Pagify{order_by: [name: :asc]}
      iex> to_query(f, for: Pagify.Factory.Post)
      []

  Encoding the query as a string:

      iex> f = %Pagify{order_by: [name: :desc, age: :asc]}
      iex> to_query(f)
      [order_by: ["-name", "age"]]
      iex> f |> to_query |> Plug.Conn.Query.encode()
      "order_by[]=-name&order_by[]=age"

      iex> f = %Pagify{filters: %{"comments_count" => %{"gt" => 2}}}
      iex> to_query(f)
      [filters: %{"comments_count" => %{"gt" => 2}}]
      iex> f |> to_query |> Plug.Conn.Query.encode()
      "filters[comments_count][gt]=2"
  """
  @spec to_query(Pagify.t(), Keyword.t()) :: Keyword.t()
  def to_query(%Pagify{} = pagify, opts \\ []) do
    default_limit = Pagify.get_option(:default_limit, opts)

    default_order = :default_order |> Pagify.get_option(opts, nil) |> Pagify.concat_sort()
    current_order = Pagify.concat_sort(pagify.order_by)

    []
    |> Misc.maybe_put(:offset, pagify.offset, 0)
    |> Misc.maybe_put(:limit, pagify.limit, default_limit)
    |> Misc.maybe_put(:order_by, current_order, default_order)
    |> Misc.maybe_put(:filters, pagify.filters)
  end

  @doc """
  Builds a path that includes query parameters for the given `Pagify` struct
  using the referenced Components path helper function.

  The first argument can be either one of:

  - an MFA tuple (module, function name as atom, arguments)
  - a 2-tuple (function, arguments)
  - a URL string, usually produced with a verified route (e.g. `~p"/some/path"`)
  - a function that takes the Pagify parameters as a keyword list as an argument

  Default values for `limit` and `order_by` are omitted from the query parameters.
  To pick up the default parameters from an `Ash.Resource`, you need to pass the
  `:for` option. If you pass a `Pagify.Meta` struct as the second argument,
  these options are retrieved from the struct automatically.

  > #### Date and Time Filters {: .info}
  >
  > When using filters on `Date`, `DateTime`, `NaiveDateTime` or `Time` fields,
  > you may need to implement the `Phoenix.Param` protocol for these structs.
  > See the documentation for `to_query/2`.

  ## Examples

  ### With a verified route

  The examples below use plain URL strings without the p-sigil, so that the
  doc tests work, but in your application, you can use verified routes or
  anything else that produces a URL.

      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> path = build_path("/posts", pagify)
      iex> %URI{path: parsed_path, query: parsed_query} = URI.parse(path)
      iex> {parsed_path, URI.decode_query(parsed_query)}
      {"/posts", %{"offset" => "20", "limit" => "10"}}

  The Pagify query parameters will be merged into existing query parameters.

      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> path = build_path("/posts?category=A", pagify)
      iex> %URI{path: parsed_path, query: parsed_query} = URI.parse(path)
      iex> {parsed_path, URI.decode_query(parsed_query)}
      {"/posts", %{"offset" => "20", "limit" => "10", "category" => "A"}}

  ### With an MFA tuple

      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> build_path(
      ...>   {Pagify.ComponentsTest, :route_helper, [%Plug.Conn{}, :posts]},
      ...>   pagify
      ...> )
      "/posts?limit=10&offset=20"

  ### With a function/arguments tuple

      iex> post_path = fn _conn, :index, query ->
      ...>   "/posts?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> build_path({post_path, [%Plug.Conn{}, :index]}, pagify)
      "/posts?limit=10&offset=20"

  We're defining fake path helpers for the scope of the doctests. In a real
  Phoenix application, you would pass something like
  `{Routes, :post_path, args}` or `{&Routes.post_path/3, args}` as the
  first argument.

  ### Passing a `Pagify.Meta` struct or a keyword list

  You can also pass a `Pagify.Meta` struct or a keyword list as the third
  argument.

      iex> post_path = fn _conn, :index, query ->
      ...>   "/posts?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> meta = %Pagify.Meta{pagify: pagify, resource: Pagify.Factory.Post}
      iex> build_path({post_path, [%Plug.Conn{}, :index]}, meta)
      "/posts?limit=10&offset=20"
      iex> query_params = to_query(pagify)
      iex> build_path({post_path, [%Plug.Conn{}, :index]}, query_params)
      "/posts?limit=10&offset=20"

  ### Additional path parameters

  If the path helper takes additional path parameters, just add them to the
  second argument.

      iex> user_post_path = fn _conn, :index, id, query ->
      ...>   "/users/\#{id}/posts?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> build_path({user_post_path, [%Plug.Conn{}, :index, 123]}, pagify)
      "/users/123/posts?limit=10&offset=20"

  ### Additional query parameters

  If the last path helper argument is a query parameter list, the Pagify
  parameters are merged into it.

      iex> post_url = fn _conn, :index, query ->
      ...>   "https://posts.pagify/posts?" <> Plug.Conn.Query.encode(query)
      ...> end
      iex> pagify = %Pagify{order_by: [name: :desc]}
      iex> build_path({post_url, [%Plug.Conn{}, :index, [user_id: 123]]}, pagify)
      "https://posts.pagify/posts?user_id=123&order_by[]=-name"
      iex> build_path(
      ...>   {post_url,
      ...>    [%Plug.Conn{}, :index, [category: "small", user_id: 123]]},
      ...>   pagify
      ...> )
      "https://posts.pagify/posts?category=small&user_id=123&order_by[]=-name"

  ### Set page as path parameter

  Finally, you can also pass a function that takes the Pagify parameters as
  a keyword list as an argument. Default values will not be included in the
  parameters passed to the function. You can use this if you need to set some
  of the parameters as path parameters instead of query parameters.

      iex> pagify = %Pagify{offset: 20, limit: 10}
      iex> build_path(
      ...>   fn params ->
      ...>     {offset, params} = Keyword.pop(params, :offset)
      ...>     query = Plug.Conn.Query.encode(params)
      ...>     if offset, do: "/posts/page/\#{offset}?\#{query}", else: "/posts?\#{query}"
      ...>   end,
      ...>   pagify
      ...> )
      "/posts/page/20?limit=10"

  Note that in this example, the anonymous function just returns a string. With
  Phoenix 1.7, you will be able to use verified routes.

      build_path(
        fn params ->
          {offset, query} = Keyword.pop(params, :offset)
          if offset, do: ~p"/posts/page/\#{offset}?\#{query}", else: ~p"/posts?\#{query}"
        end,
        pagify
      )

  Note that the keyword list passed to the path builder function is built using
  `Plug.Conn.Query.encode/2`, which means filters are formatted as maps.

  ### Set filter value as path parameter
      iex> pagify = %Pagify{
      ...>   offset: 20,
      ...>   order_by: [:updated_at],
      ...>   filters: %{
      ...>     author: "John",
      ...>   }
      ...> }
      iex> build_path(
      ...>   fn params ->
      ...>     {offset, params} = Keyword.pop(params, :offset)
      ...>     filters = Keyword.get(params, :filters, %{})
      ...>     author = Map.get(filters, :author, nil)
      ...>     filters = Map.delete(filters, :author)
      ...>     params = Keyword.put(params, :filters, filters)
      ...>     query = Plug.Conn.Query.encode(params)
      ...>
      ...>     case {offset, author} do
      ...>       {nil, nil} -> "/posts?\#{query}"
      ...>       {offset, nil} -> "/posts/page/\#{offset}?\#{query}"
      ...>       {nil, author} -> "/posts/author/\#{author}?\#{query}"
      ...>       {offset, author} -> "/posts/author/\#{author}/page/\#{offset}?\#{query}"
      ...>     end
      ...>   end,
      ...>   pagify
      ...> )
      "/posts/author/John/page/20?order_by[]=updated_at"

  ### If only path is set

  If only the path is set, it is returned as is.

      iex> build_path("/posts", nil)
      "/posts"
  """
  @spec build_path(pagination_path(), Meta.t() | Pagify.t() | Keyword.t(), Keyword.t()) ::
          String.t()
  def build_path(path, meta_or_pagify_or_params, opts \\ [])

  def build_path(path, %Meta{pagify: pagify, resource: resource}, opts) when is_atom(resource) and resource != nil do
    build_path(path, pagify, Keyword.put(opts, :for, resource))
  end

  def build_path(path, %Pagify{} = pagify, opts) do
    build_path(path, to_query(pagify, opts))
  end

  def build_path({module, func, args}, pagify_params, _opts)
      when is_atom(module) and is_atom(func) and is_list(args) and is_list(pagify_params) do
    final_args = build_final_args(args, pagify_params)
    apply(module, func, final_args)
  end

  def build_path({func, args}, pagify_params, _opts)
      when is_function(func) and is_list(args) and is_list(pagify_params) do
    final_args = build_final_args(args, pagify_params)
    apply(func, final_args)
  end

  def build_path(func, pagify_params, _opts) when is_function(func, 1) and is_list(pagify_params) do
    func.(pagify_params)
  end

  def build_path(uri, pagify_params, _opts) when is_binary(uri) and is_list(pagify_params) do
    pagify_params_map = Map.new(pagify_params)
    build_path(uri, pagify_params_map)
  end

  def build_path(uri, pagify_params, _opts) when is_binary(uri) and is_map(pagify_params) do
    uri = URI.parse(uri)

    query =
      (uri.query || "")
      |> Query.decode()
      |> Map.merge(Misc.remove_nil_values(pagify_params))

    query = if query != %{}, do: Query.encode(query)

    uri
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  def build_path(uri, nil, _opts) when is_binary(uri) do
    uri
  end

  defp build_final_args(args, pagify_params) do
    case Enum.reverse(args) do
      [last_arg | rest] when is_list(last_arg) ->
        query_arg = Keyword.merge(last_arg, pagify_params)
        Enum.reverse([query_arg | rest])

      _ ->
        args ++ [pagify_params]
    end
  end
end
