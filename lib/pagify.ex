defmodule Pagify do
  @moduledoc """
  Pagify is an Elixir library designed to easily apply filtering, ordering, and pagination to
  your `Ash` queries.

  ## Features

  - **Offset-based pagination**: Pagify uses `OFFSET` and `LIMIT` to paginate your queries.
  - **Sorting**: Sort your queries by multiple fields and any directions.
  - **Filtering**: Apply filters to your queries using a simple map syntax. Allows complex data
  filtering using multiple conditions, operators, and fields.
  - **UI helpers and URL builders**: Pagify provides a `Pagify.Meta` struct with information about
  the current page, total pages, and more. This information can be used to build pagination links
  in your UI.

  ## Installation

  Add `Ash` to your project's dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:ash, "~> 2.13"},
      {:ash_phoenix, "~> 1.2"},
      {:ash_postgres, "~> 1.3"},
      {:ash_uuid, "~> 0.7"}
    ]
  end
  ```

  Then simply copy the `Pagify` module into your project's lib folder. No additional dependencies are required.

  Replace the `:my_app` atom with the name of your application in the following places:
  - `config/config.exs` (for the global configuration)
  - `lib/pagify/pagify.ex`
  - `lib/pagify/components/pagination.ex`
  - `lib/pagify/components/table.ex`

  If you want to include the tests, you can copy the `test/pagify` directory as well. In this case, you
  will need to add the `test/pagify/support` folder to `elixir_paths(:test)` in your `mix.exs` file. You
  will also need to add the `ex_machina` dependency to your `deps` function.

  ```elixir
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/pagify/support"]

  # ...

  def deps do
    [
      # ...
      {:ex_machina, "~> 2.7.0", only: :test}
    ]
  end
  ```

  ## Global configuration

  You can set some global options like the default_limit via the application
  environment. All global options can be overridden by passing them directly to
  the functions.
      config :my_app, :pagify,
        default_limit: 50,
        max_limit: 1000,
        replace_invalid_params?: true

  See `t:Pagify.option/0` for a description of all available options.

  ## Usage

  First, define a function that utilizes Pagify.validate_and_run/4 to query your desired list.
  For example in your Ash resource module, you can define a function that queries a list of posts.
  You need to add the pagination macro call to the action of the resource that you
  want to be paginated. The macro call is used to set the default limit, offset and
  other options for the pagination.

  ```elixir
  defmodule YourApp.Resource.Post
    @default_limit 15
    def default_limit, do: @default_limit

    actions do
      read :read do
        #...
        pagination offset?: true,
                  default_limit: @default_limit,
                  countable: true,
                  required?: false
      end
    end
    #...
  end
  ```

  ### LiveView

  In the LiveView, fetch the data and assign it alongside the meta data to the socket.

  ```elixir
  defmodule YourAppWeb.PostLive.IndexLive do
    use YourAppWeb, :live_view

    alias YourApp.Resource.Post

    @impl true
    def handle_params(params, _, socket) do
      case Post.list_posts(params) do
        {:ok, {posts, meta}} ->
          {:noreply, assign(socket, %{posts: posts, meta: meta})}
        {:error, _meta} ->
          # This will reset invalid parameters. Alternatively, you can assign
          # only the meta and render the errors, or assign the validated params,
          # or you can ignore the error case entirely.
          {:noreply, push_navigate(socket, to: ~p"/posts")}
      end
    end

    defp list_posts(params, opts \\\\ []) do
      Pagify.validate_and_run(Post, params, opts)
    end
  end
  ```

  ### LiveView streams

  To use LiveView streams, you can change your `handle_params/3` function as follows:

  ```elixir
  def handle_params(params, _, socket) do
    case Post.list_posts(params) do
      {:noreply,
         socket
         |> assign(:meta, meta)
         |> stream(:posts, posts, reset: true)}
    # ...
    end
  end
  ```

  ### Replace invalid params

  To replace invalid pagify parameters with their default values, you can use the `replace_invalid_params?`
  option. You can change your `handle_params/3` function as follows:

  ```elixir
  def handle_params(params, _, socket) do
    case Post.list_posts(params, replace_invalid_params?: true) do
        {:ok, {posts, meta}} ->
          {:noreply, assign(socket, %{posts: posts, meta: meta})}
        {:error, meta} ->
          valid_path = Pagify.Components.build_path(~p"/posts", meta.params)
          {:noreply, push_navigate(socket, to: valid_path)}
    # ...
    end
  end
  ```

  ## Sortable tables and pagination

  To add a sortable table and pagination links, you can add the following to your template:

  ```heex
  <h1>Posts</h1>

  <Pagify.Components.table items={@posts} meta={@meta} path={~p"/posts"}>
    <:col :let={post} label="Name" field={:name}><%= post.name %></:col>
    <:col :let={post} label="Author" field={:author}><%= post.author %></:col>
  </Pagify.Components.table>

  <Pagify.Components.pagination meta={@meta} path={~p"/posts"} />
  ```

  In this context, path points to the current route, and Pagify Components appends
  pagination, filtering, and sorting parameters to it. You can use verified
  routes, route helpers, or custom path builder functions. You'll find
  explanations for the different formats in the documentation for
  `Pagify.Components.build_path/3`.

  Note that the field attribute in the `:col` slot is optional. If set and the
  corresponding field in the resource is defined as sortable, the table header for
  that column will be interactive, allowing users to sort by that column. However,
  if the field isn't defined as sortable, or if the field attribute is omitted, or
  set to `nil` or `false`, the table header will not be clickable.

  By using the `for` option in your Pagify query, Pagify Components can identify which
  table columns are sortable. Additionally, it omits the `order_by` and `limit`
  parameters if they align with the default values specified either in your resoruce or
  in the Pagify module.

  You also have the option to pass a `Phoenix.LiveView.JS` command instead of or
  in addition to a path. For more details, please refer to the component
  documentation.

  ## Parameter format

  The Pagify library requires parameters to be provided in a specific format as a map.
  This map can be translated into a URL query parameter string, typically for use in a
  web framework like Phoenix.

  ## Pagination

  You can specify an offset to start from and a limit to the number of results.

      %{offset: 100, limit: 20}

  This translates to the following query parameter string:

  ```URL
  ?offset=100&limit=20
  ```

  ## Ordering

  To add an ordering clause to a query, you need to set the `:order_by`
  parameter. `:order_by` should be a list of fields or calculations
  available in your resource. The order direction can be set by adding
  one of the following prefixes to the field name:

  - `""` or `+` for ascending order
  - `-` for descending order
  - `++` for ascending order with nulls first
  - `--` for descending order with nulls last

  If no order directions are given, `:asc` is used as default.

      iex> params = %{order_by: ["name", "--author"]}
      iex> {:ok, pagify} = Pagify.validate(Post, params)
      iex> pagify.order_by
      [{:name, :asc}, {:author, :desc_nils_last}]

  This translates to the following query parameter string:

  ```URL
  ?order_by=name,--author
  ```

  ## Filters

  Filters can be passed as a list of maps or plain maps.

      iex> params = %{filters: %{name: "Post 1"}}
      iex> {:ok, {results, meta}} = Pagify.validate_and_run(Post, params)
      iex> meta.total_count
      1
      iex> [post] = results
      iex> post.name
      "Post 1"

  This translates to the following query parameter string:

  ```URL
  ?filters[name]=Post%201
  ```

  See `Ash.Query.filter_input/2` for a list of all available filter operators.

  ## Internal parameters

  Pagify is designed to manage parameters that come from the user side. While it is
  possible to alter those parameters and append extra filters upon receiving them,
  it is advisable to clearly differentiate parameters coming from outside and the
  parameters that your application adds internally.

  Consider the scenario where you need to scope a query based on the current user.
  In this case, it is better to create a separate function that introduces the
  necessary filter clauses:

  ```elixir
  def list_posts(%{} = params, %User{} = current_user) do
    Post
    |> scope(current_user)
    |> Pagify.validate_and_run(params)
  end

  defp scope(query, %User{role: :admin}), do: query
  defp scope(query, %User{id: user_id}), do: Ash.Query.filter_input(query, %{user_id: ^user_id})
  ```

  If you need to add extra filters that are only used internally and aren't exposed to the user,
  you can pass them as a separate argument. This same argument can be used to override certain
  options depending on the context in which the function is called.

  ```elixir
  def list_posts(%{} = params, opts \\ [], %User{} = current_user) do
    pagify_opts =
      opts
      |> Keyword.put(:max_limit, 10)
      |> Keyword.put(:default_limit, 10)
      |> Keyword.put(:replace_invalid_params?, true)

    Post
    |> scope(current_user)
    |> apply_filters(opts)
    |> Pagify.validate_and_run(params, pagify_opts)
  end

  defp scope(query, %User{role: :admin}), do: query
  defp scope(query, %User{id: user_id}), do: Ash.Query.filter_input(query, %{user_id: ^user_id})

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:updated_at, dt}, query -> Ash.Query.filter_input(query, %{updated_at: dt})
      _, query -> query
    end)
  end
  ```

  With this approach, you maintain a clean separation between user-driven parameters and
  system-driven parameters, leading to more maintainable and less error-prone code. Please be
  aware that in most cases it is better to use `Ash.Policy` to manage access control. This
  example is just to illustrate the concept.

  Under the hood, the `Pagify.validate_and_run/4` or `Pagify.validate_and_run!/4` functions
  just call `Pagify.validate/2` and `Pagify.run/4`, which in turn calls `Pagify.all/4` and
  `Pagify.meta/3`.

  See `Pagify.Meta` for descriptions of the meta fields.

  Alternatively, you may separate parameter validation and data fetching into different
  steps using the `Pagify.validate/2`, `Pagify.validate!/2`, and `Pagify.run/4` functions.
  This allows you to manipulate the validated parameters, to modify the query depending on
  the parameters, or to move the parameter validation to a different layer of your application.

  ```elixir
  with {:ok, pagify} <- Pagify.validate(Post, params) do
    {:ok, {results, meta}} = Pagify.run(Post, pagify)
  end
  ```

  The aforementioned functions internally call the lower-level functions `Pagify.all/4` and
  `Pagify.meta/3`. If you have advanced requirements, you might prefer to use these functions
  directly. However, it's important to note that these lower-level functions do not validate
  the parameters. If parameters are generated based on user input, they should always be
  validated first using `Pagify.validate/2` or `Pagify.validate!/2` to ensure safe execution.
  """
  alias Ash.Resource.Info
  alias Pagify.Meta
  alias Pagify.Validation

  require Logger

  @default_opts [default_limit: 25, max_limit: 100, replace_invalid_params?: false]
  @default_opts_keys Enum.map(@default_opts, fn {k, _} -> k end)

  defstruct limit: nil, offset: nil, filters: nil, order_by: nil

  @typedoc """
  These options can be passed to most functions or configured via the
  application environment.

  ## Options

  Default pagify options in addition to the ones provided by the
  `c:Ash.Api.read/2` function. These options are used to configure the
  pagination behavior.

  - `:default_limit` - The default number of records to return. Defaults to 25.
    Can be overridden by the resource's `default_limit` function.
  - `:max_limit` - The maximum number of records that can be returned. Defaults
    to 100.
  - `:replace_invalid_params?` - If set to `true`, invalid parameters will be
    replaced with the default value. If set to `false`, invalid parameters
    will result in an error. Defaults to `false`.

  ## Look-up order

  Options are looked up in the following order:

  1. Function arguments
  2. Resource-level options
  3. Global options in the application environment
  4. Library defaults

  """
  @type option ::
          {default_limit :: non_neg_integer()}
          | {max_limit :: non_neg_integer()}
          | {replace_invalid_params? :: boolean()}

  @typedoc """
  Valid order_by types for the `t:Pagify.t/0` struct.
  """
  @type order_by :: [atom() | String.t() | {atom(), Ash.Sort.sort_order()} | [String.t()]] | nil

  @typedoc """
  Represents the query parameters for filtering, ordering and pagination.

  ### Fields

  - `limit`, `offset`: Used for offset-based pagination.
  - `filters`: A map of filters to apply to the query (see `AshPhoenix.FilterForm` for examples).
  - `order_by`: A list of fields to order by (see `Ash.Sort.parse_input/3` for all available orders).
  """
  @type t :: %__MODULE__{
          limit: pos_integer() | nil,
          offset: non_neg_integer() | nil,
          filters: map() | Keyword.t() | nil,
          order_by: order_by()
        }

  @doc """
  Adds clauses for filtering, ordering and pagination to an `t:Ash.Query.t/0` or
  `t:Ash.Resource.t/0` from the given `t:Pagify.t/0` parameters and `t:Keyword.t/0`
  options.

  The keyword list `opts` is used to pass additional options to the query engine.
  It shoud conform to the list of valid options at `c:Ash.Api.read/2`.

  We take the keyword list `opts` and return a keyword list callback according to
  `c:Ash.Api.read/2` but with the __:query__ keyword also within the list.

  - `Pagify.filters` and `Pagify.order_by` are used to filter and order the query.
  - `Pagify.limit` and `Pagify.offset` are used to paginate the query.

  The user input parameters are represented by the `t:Pagify.t/0` type. Any `nil` values
  will be ignored.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 10, offset: 20, filters: %{name: "foo"}, order_by: ["name"]}
      iex> [page, {:query, query}] = parse(Post, pagify)
      iex> page
      {:page, [count: true, offset: 20, limit: 10]}
      iex> query
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">, sort: [{"name", :asc}]>

  Or to disable counting:

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 10, offset: 20, filters: %{name: "foo"}, order_by: ["name"]}
      iex> [page, {:query, query}] = parse(Post, pagify, page: [count: false])
      iex> page
      {:page, [count: false, offset: 20, limit: 10]}
      iex> query
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">, sort: [{"name", :asc}]>

  Sorting only:

        iex> alias Pagify.Factory.Post
        iex> pagify = %Pagify{order_by: ["name"]}
        iex> [page, {:query, query}] = parse(Post, pagify)
        iex> page
        {:page, [count: true, offset: 0, limit: 15]}
        iex> query
        #Ash.Query<resource: Pagify.Factory.Post, sort: [{"name", :asc}]>

  Filtering only:

        iex> alias Pagify.Factory.Post
        iex> pagify = %Pagify{filters: %{name: "foo"}}
        iex> [page, {:query, query}] = parse(Post, pagify)
        iex> page
        {:page, [count: true, offset: 0, limit: 15]}
        iex> query
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">>

  Pagination only:

        iex> alias Pagify.Factory.Post
        iex> pagify = %Pagify{limit: 10, offset: 20}
        iex> [page, {:query, query}] = parse(Post, pagify)
        iex> page
        {:page, [count: true, offset: 20, limit: 10]}
        iex> query
        #Ash.Query<resource: Pagify.Factory.Post>

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec parse(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) :: Keyword.t()
  def parse(query_or_resource, pagify, opts \\ [])

  def parse(%Ash.Query{} = q, %Pagify{} = pagify, opts) do
    opts = Keyword.put(opts, :query, query(q, pagify))
    paginate(q, pagify, opts)
  end

  def parse(r, %Pagify{} = pagify, opts) when is_atom(r) and r != nil do
    parse(Ash.Query.to_query(r), pagify, opts)
  end

  @doc """
  Returns an `t:Ash.Page.Offset.t/0` struct from the given `t:Ash.Query.t/0` or `t:Ash.Resource.t/0`
  with the given `t:Pagify.t/0` parameters and `t:Keyword.t/0` options.

  The `opts` keyword list is used to pass additional options to the query engine.
  It should conform to the list of valid options at `c:Ash.Api.read/2`.

  - `Pagify.filters` and `Pagify.order_by` are used to filter and order the query.
  - `Pagify.limit` and `Pagify.offset` are used to paginate the query.

  The user input parameters are represented by the `t:Pagify.t/0` type. Any `nil` values
  will be ignored.

  If the `:action` option is set (to perform a custom read action), the fourth argument
  `args` will be passed to the action as arguments.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> %Ash.Page.Offset{results: r} =  Pagify.all(Post, %Pagify{filters: %{name: "inexistent"}})
      iex> r
      []

  Or with an initial query:

      iex> alias Pagify.Factory.Post
      iex> q = Ash.Query.filter_input(Post, %{name: "inexistent"})
      iex> %Ash.Page.Offset{results: r} = Pagify.all(q, %Pagify{})
      iex> r
      []

  Or with a custom read action:
      iex> alias Pagify.Factory.Post
      iex> alias Pagify.Factory.Comment
      iex> Comment.read!() |> Enum.count()
      9
      iex> pagify = %Pagify{limit: 1, filters: %{name: "Post 1"}}
      iex> %Ash.Page.Offset{results: posts} = Pagify.all(Post, pagify)
      iex> post = hd(posts)
      iex> %Ash.Page.Offset{count: count} = Pagify.all(Comment, %Pagify{}, [action: :by_post], post.id)
      iex> count
      2

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec all(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t(), any()) ::
          Ash.Page.Offset.t()
  def all(query_or_resource, pagify, opts \\ [], args \\ nil)

  def all(%Ash.Query{resource: r} = q, %Pagify{} = pagify, opts, args) do
    opts = remove_pagify_opts(opts)
    opts = parse(q, pagify, opts)

    case Keyword.get(opts, :action) do
      nil ->
        r.read!(opts)

      action ->
        {:ok, page} = apply(r, action, [args, opts])
        page
    end
  end

  def all(r, %Pagify{} = pagify, opts, args) when is_atom(r) and r != nil do
    all(Ash.Query.to_query(r), pagify, opts, args)
  end

  defp remove_pagify_opts(opts) do
    Enum.filter(opts, fn {k, _} -> !Enum.member?(@default_opts_keys, k) end)
  end

  @doc """
  Applies the given `t:Pagify.t/0` to the given `t:Ash.Query.t/0` or `t:Ash.Resource.t/0`,
  retrieves the data and the `t:Pagify.Meta.t/0` data.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine. Or you can use `Pagify.validate_and_run/4` or
  `Pagify.validate_and_run!/4` instead of this function.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> opts = [page: [count: false]]
      iex> pagify = Pagify.validate!(Post, %{filters: %{name: "inexistent"}}, opts)
      iex> {data, meta} = Pagify.run(Post, pagify, opts)
      iex> data == []
      true
      iex> match?(%Pagify.Meta{}, meta)
      true

  See the documentation for `Pagify.validate_and_run/4` for supported options.
  """
  @spec run(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t(), any()) ::
          {[Ash.Resource.record()], Meta.t()}
  def run(query_or_resource, pagify, opts \\ [], args \\ nil)

  def run(%Ash.Query{} = q, %Pagify{} = pagify, opts, args) do
    page = all(q, pagify, opts, args)
    meta = meta(page, pagify, opts)
    {page.results, meta}
  end

  def run(r, %Pagify{} = pagify, opts, args) when is_atom(r) and r != nil do
    run(Ash.Query.to_query(r), pagify, opts, args)
  end

  @doc """
  Validates the given pagify parameters and retrieves the data and meta data on
  success.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> {:ok, {[%Post{},%Post{},%Post{}], %Pagify.Meta{}}} =
      ...>   Pagify.validate_and_run(Post, %Pagify{})
      iex> {:error, %Pagify.Meta{} = meta} =
      ...>   Pagify.validate_and_run(Post, %{limit: -1})
      iex> Pagify.Error.clear_stacktrace(meta.errors)
      [
        limit: [
          %Ash.Error.Query.InvalidLimit{limit: -1}
        ]
      ]

  Or with a custom read action:

      iex> alias Pagify.Factory.Post
      iex> alias Pagify.Factory.Comment
      iex> Comment.read!() |> Enum.count()
      9
      iex> pagify = %Pagify{limit: 1, filters: %{name: "Post 1"}}
      iex> {:ok, {posts, _meta}} = Pagify.validate_and_run(Post, pagify)
      iex> post = hd(posts)
      iex> {:ok, {_comments, meta}} = Pagify.validate_and_run(Comment, %Pagify{}, [action: :by_post], post.id)
      iex> meta.total_count
      2

  ## Options

  The keyword list `opts` is used to pass additional options to the query engine.
  It shoud conform to the list of valid options at `c:Ash.Api.read/2`. Furthermore
  the `t:Pagify.option/0` library options are supported.
  """
  @spec validate_and_run(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t(), any()) ::
          {:ok, {[Ash.Resource.record()], Meta.t()}} | {:error, Meta.t()}
  def validate_and_run(query_or_resource, map_or_pagify, opts \\ [], args \\ nil) do
    with {:ok, pagify} <- validate(query_or_resource, map_or_pagify, opts) do
      {:ok, run(query_or_resource, pagify, opts, args)}
    end
  end

  @doc """
  Same as `Pagify.validate_and_run/4`, but raises on error.
  """
  @spec validate_and_run!(
          Ash.Query.t() | Ash.Resource.t(),
          map() | Pagify.t(),
          Keyword.t(),
          any()
        ) ::
          {[Ash.Resource.record()], Meta.t()}
  def validate_and_run!(query_or_resource, map_or_pagify, opts \\ [], args \\ nil) do
    pagify = validate!(query_or_resource, map_or_pagify, opts)
    run(query_or_resource, pagify, opts, args)
  end

  @doc """
  Returns meta information for the given query and pagify that can be used for
  building the pagination links.

  # Examples

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 2, offset: 1, order_by: [name: :asc, comments_count: :desc_nils_last]}
      iex> page = Pagify.all(Post, pagify)
      iex> Pagify.meta(page, pagify)
      %Pagify.Meta{
        current_limit: 2,
        current_offset: 1,
        current_order_by: ["name", "--comments_count"],
        current_page: 2,
        has_next_page?: false,
        has_previous_page?: true,
        next_offset: nil,
        opts: [],
        pagify: %Pagify{filters: nil, limit: 2, offset: 1, order_by: [name: :asc, comments_count: :desc_nils_last]},
        previous_offset: 0,
        resource: Post,
        total_count: 3,
        total_pages: 2
      }

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec meta(Ash.Page.Offset.t(), Pagify.t(), Keyword.t()) :: Meta.t()
  def meta(%Ash.Page.Offset{} = page, %Pagify{} = pagify, opts \\ []) do
    total_count = page.count
    page_size = page.limit
    total_pages = get_total_pages(total_count, page_size)
    current_offset = get_current_offset(page.offset)
    current_page = get_current_page(page, total_pages)

    {has_previous_page?, previous_offset} = get_previous(current_offset, page_size)
    {has_next_page?, next_offset} = get_next(current_offset, page_size, total_count)

    current_order_by = get_current_order_by(pagify)
    resource = get_resource(page)

    %Meta{
      current_limit: page_size,
      current_offset: current_offset,
      current_order_by: current_order_by,
      current_page: current_page,
      has_next_page?: has_next_page?,
      has_previous_page?: has_previous_page?,
      next_offset: next_offset,
      opts: opts,
      pagify: pagify,
      previous_offset: previous_offset,
      resource: resource,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  defp get_resource(%Ash.Page.Offset{rerun: {original_query, _}}), do: original_query.resource

  defp get_previous(offset, limit) do
    has_previous? = offset > 0
    previous_offset = if has_previous?, do: max(0, offset - limit), else: 0

    {has_previous?, previous_offset}
  end

  defp get_next(_, nil = _page_size, _) do
    {false, nil}
  end

  defp get_next(current_offset, page_size, total_count) when current_offset + page_size >= total_count do
    {false, nil}
  end

  defp get_next(current_offset, page_size, _) do
    {true, current_offset + page_size}
  end

  defp get_total_pages(0, _), do: 0
  defp get_total_pages(nil, _), do: 0
  defp get_total_pages(_, nil), do: 1
  defp get_total_pages(total_count, limit), do: ceil(total_count / limit)

  defp get_current_offset(nil), do: 0
  defp get_current_offset(offset), do: offset

  defp get_current_page(%Ash.Page.Offset{offset: nil}, _), do: 1

  defp get_current_page(%Ash.Page.Offset{offset: offset, limit: limit}, total_pages) do
    page = ceil(offset / limit) + 1
    min(page, total_pages)
  end

  defp get_current_order_by(%Pagify{order_by: nil}), do: nil
  defp get_current_order_by(%Pagify{order_by: order_by}), do: concat_sort(order_by)

  @doc """
  Transforms the given `order_by` parameter into a list of strings (user input domain).
  """
  @spec concat_sort(order_by(), [String.t()]) :: [String.t()]
  def concat_sort(list, acc \\ [])
  def concat_sort(nil, _), do: nil
  def concat_sort([], []), do: nil
  def concat_sort([], acc), do: Enum.reverse(acc)
  def concat_sort(order_by, acc) when is_binary(order_by), do: concat_sort([order_by], acc)
  def concat_sort(order_by, acc) when is_atom(order_by), do: concat_sort([order_by], acc)
  def concat_sort(order_by, acc) when is_tuple(order_by), do: concat_sort([order_by], acc)

  def concat_sort([field | rest], acc) do
    case field do
      {field, order} ->
        concat_sort(rest, ["#{order_to_prefix(order)}#{Atom.to_string(field)}" | acc])

      field when is_binary(field) ->
        concat_sort(rest, [field | acc])

      field when is_atom(field) ->
        concat_sort(rest, [Atom.to_string(field) | acc])
    end
  end

  defp order_to_prefix(:asc_nils_first), do: "++"
  defp order_to_prefix(:desc), do: "-"
  defp order_to_prefix(:desc_nils_last), do: "--"
  defp order_to_prefix(_), do: ""

  @doc """
  Transforms the given field with order prefix into an `t:Ash.Sort.sort_order/t`.

  ## Examples

      iex> Pagify.prefix_to_order("name")
      :asc
      iex> Pagify.prefix_to_order("-name")
      :desc
      iex> Pagify.prefix_to_order("++name")
      :asc_nils_first
      iex> Pagify.prefix_to_order("--name")
      :desc_nils_last
      iex> Pagify.prefix_to_order("+name")
      :asc
  """
  @spec prefix_to_order(String.t()) :: Ash.Sort.sort_order()
  def prefix_to_order("++" <> field) when is_binary(field), do: :asc_nils_first
  def prefix_to_order("--" <> field) when is_binary(field), do: :desc_nils_last
  def prefix_to_order("+" <> field) when is_binary(field), do: :asc
  def prefix_to_order("-" <> field) when is_binary(field), do: :desc
  def prefix_to_order(_), do: :asc

  # Query

  @doc """
  Adds clauses for filtering and ordering to an `t:Ash.Query.t/0` from the given
  `t:Pagify.t/0` parameter.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> q = Ash.Query.to_query(Post)
      iex> pagify = %Pagify{filters: %{name: "John"}, order_by: ["name"]}
      iex> query(q, pagify)
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "John">, sort: [{"name", :asc}]>
  """
  @spec query(Ash.Query.t(), Pagify.t()) :: Ash.Query.t()
  def query(%Ash.Query{} = q, %Pagify{} = pagify) do
    q
    |> filter(pagify)
    |> order_by(pagify)
  end

  ## Filter

  @doc """
  Applies the `filter` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. See `Ash.Query.filter_input/2` for more information.

  For a completed list of filter operators, see `Ash.Filter`.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{filters: %{name: "foo"}}
        iex> filter(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">>

  Or multiple filters:

        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{filters: %{name: "foo", id: "1"}}
        iex> filter(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<id == "1" and name == "foo">>

  Or by relation:

        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{filters: %{comments: %{body: "foo"}}}
        iex> filter(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<comments.body == "foo">>
  """
  @spec filter(Ash.Query.t(), Pagify.t()) :: Ash.Query.t()
  def filter(q, pagify)

  def filter(%Ash.Query{} = q, %Pagify{filters: nil}), do: q
  def filter(%Ash.Query{} = q, %Pagify{filters: []}), do: q

  def filter(%Ash.Query{} = q, %Pagify{filters: filters}) do
    Ash.Query.filter_input(q, filters)
  end

  def filter(%Ash.Query{} = q, _), do: q

  ## Ordering

  @doc """
  Applies the `order_by` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. See `Ash.Query.sort_input/2` for more information.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{order_by: ["name"]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [{"name", :asc}]>

  Or descending order nulls last:
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{order_by: [name: :desc_nils_last]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [name: :desc_nils_last]>

  Or multiple fields:
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{order_by: ["name", "id"]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [{"name", :asc}, {"id", :asc}]>

  Or by calculation:
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.to_query(Post)
        iex> pagify = %Pagify{order_by: ["comments_count"]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [comments_count: :asc]>
  """
  @spec order_by(Ash.Query.t(), Pagify.t()) :: Ash.Query.t()
  def order_by(q, pagify)

  def order_by(%Ash.Query{} = q, %Pagify{order_by: nil}), do: q
  def order_by(%Ash.Query{} = q, %Pagify{order_by: []}), do: q

  def order_by(%Ash.Query{} = q, %Pagify{order_by: order_by}) do
    Ash.Query.sort_input(q, order_by)
  end

  def order_by(%Ash.Query{} = q, _), do: q

  # Pagination

  @doc """
  Adds clauses for pagination to the resulting keyword list from the given
  `t:Pagify.t/0` parameter.

  The `count` parameter is set to `true` by default. To disable counting the
  total number of records, set `page: [:count, false]` in the opts keyword list.

  If the `limit` or `offset` fields are `nil`, the default limit and offset
  values will be used.

  If the resource itself provides a default limit, it will be used instead of
  the default limit provided by Pagify.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 10, offset: 20}
      iex> paginate(Post, pagify)
      [page: [count: true, offset: 20, limit: 10]]

  Or disable counting:

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 10, offset: 20}
      iex> paginate(Post, pagify, page: [count: false])
      [page: [count: false, offset: 20, limit: 10]]

  Or without the offset parameter:

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 8}
      iex> paginate(Post, pagify)
      [page: [count: true, offset: 0, limit: 8]]

  Or without the limit parameter. The default limit from Post will be used:

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{offset: 5}
      iex> paginate(Post, pagify)
      [page: [count: true, offset: 5, limit: 15]]

  Or without the limit parameter. The default limit from Pagify will be used if no
  default limit is provided by the resource:

      iex> alias Pagify.Factory.Comment
      iex> pagify = %Pagify{offset: 5}
      iex> paginate(Comment, pagify)
      [page: [count: true, offset: 5, limit: 25]]

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec paginate(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) :: Keyword.t()
  def paginate(query_or_resource, pagify, opts \\ [])

  def paginate(%Ash.Query{} = q, %Pagify{} = pagify, opts) do
    page_opts = Keyword.get(opts, :page)

    page =
      q
      |> put_default_limit(pagify)
      |> page(page_opts)

    Keyword.put(opts, :page, page)
  end

  def paginate(r, pagify, opts) when is_atom(r) and r != nil do
    paginate(Ash.Query.to_query(r), pagify, opts)
  end

  @spec put_default_limit(Ash.Query.t(), Pagify.t()) :: Pagify.t()
  defp put_default_limit(q, pagify)

  defp put_default_limit(%Ash.Query{resource: r}, %Pagify{limit: nil} = pagify) when is_atom(r) and r != nil do
    %{pagify | limit: get_option(:default_limit, for: r)}
  end

  defp put_default_limit(_, %Pagify{limit: nil} = pagify) do
    %{pagify | limit: get_option(:default_limit)}
  end

  defp put_default_limit(_, pagify), do: pagify

  @doc """
  Returns a keyword list with the `limit`, `offset` and `count` parameters
  from the given `t:Pagify.t/0` parameter.

  The `count` parameter is set to `true` by default. To disable counting the
  total number of records, set `count: false` in the optional page keyword list.

  ## Examples

      iex> pagify = %Pagify{limit: 10, offset: 20}
      iex> page(pagify)
      [count: true, offset: 20, limit: 10]

  Or disable counting:

      iex> pagify = %Pagify{limit: 10, offset: 20}
      iex> page(pagify, count: false)
      [count: false, offset: 20, limit: 10]
  """
  @spec page(Pagify.t(), Keyword.t()) :: Keyword.t()
  def page(pagify, page \\ [count: true])

  def page(%Pagify{limit: limit, offset: offset}, count: count)
      when is_integer(limit) and limit >= 1 and (is_integer(offset) and offset >= 0) do
    []
    |> Keyword.put(:limit, limit)
    |> Keyword.put(:offset, offset)
    |> Keyword.put(:count, count)
  end

  def page(%Pagify{limit: limit, offset: offset}, count: count)
      when is_integer(limit) and limit >= 1 and is_nil(offset) do
    []
    |> Keyword.put(:limit, limit)
    |> Keyword.put(:offset, 0)
    |> Keyword.put(:count, count)
  end

  def page(%Pagify{limit: limit, offset: offset}, count: count)
      when is_nil(limit) and (is_integer(offset) and offset >= 0) do
    []
    |> Keyword.put(:limit, get_option(:default_limit))
    |> Keyword.put(:offset, offset)
    |> Keyword.put(:count, count)
  end

  def page(%Pagify{limit: limit, offset: offset}, _)
      when is_integer(limit) and limit >= 1 and (is_integer(offset) and offset >= 0) do
    []
    |> Keyword.put(:limit, limit)
    |> Keyword.put(:offset, offset)
    |> Keyword.put(:count, true)
  end

  def page(%Pagify{limit: limit, offset: offset}, _) when is_integer(limit) and limit >= 1 and is_nil(offset) do
    []
    |> Keyword.put(:limit, limit)
    |> Keyword.put(:offset, 0)
    |> Keyword.put(:count, true)
  end

  def page(%Pagify{limit: limit, offset: offset}, _) when is_nil(limit) and (is_integer(offset) and offset >= 0) do
    []
    |> Keyword.put(:limit, get_option(:default_limit))
    |> Keyword.put(:offset, offset)
    |> Keyword.put(:count, true)
  end

  # Validation

  @doc """
  Validates a `t:Pagify.t/0`.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> params = %{limit: 10, offset: 20, other_param: "foo"}
      iex> Pagify.validate(Post, params)
      {:ok, %Pagify{limit: 10, offset: 20}}

      iex> pagify = %Pagify{offset: -1}
      iex> {:error, %Pagify.Meta{} = meta} = Pagify.validate(Post, pagify)
      iex> Pagify.Error.clear_stacktrace(meta.errors)
      [
        offset: [
          %Ash.Error.Query.InvalidOffset{offset: -1}
        ]
      ]

  The function is aware of the `Ash.Resource` type passed either as query or as
  resource. Thus the function is able to validate that only allowed fields are
  used for ordering and filtering. The function will also apply the default_limit
  if the resource provides one.

  You need to add the pagination macro call to the action of the resource that you
  want to be paginated. The macro call is used to set the default limit, offset and
  other options for the pagination.

      defmodule Your.Ash.Resource
        @default_limit 15
        def default_limit, do: @default_limit

        actions do
          read :read do
            ...
            pagination offset?: true,
                      default_limit: @default_limit,
                      countable: true,
                      required?: false
          end
        end
      end
  """
  @spec validate(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t()) ::
          {:ok, Pagify.t()} | {:error, Meta.t()}
  def validate(query_or_resource, map_or_pagify, opts \\ [])

  def validate(query_or_resource, %Pagify{} = pagify, opts) do
    map = pagify_struct_to_map(pagify)
    validate(query_or_resource, map, opts)
  end

  def validate(query_or_resource, %{} = params, opts) do
    result =
      Validation.validate_params(query_or_resource, params, opts)

    case result do
      {:ok, _} ->
        result

      {:error, errors, maybe_valid_params} ->
        Logger.debug("Invalid Pagify: #{inspect(errors)}")
        {:error, Meta.with_errors(maybe_valid_params, errors, opts)}
    end
  end

  defp pagify_struct_to_map(%Pagify{} = pagify) do
    pagify
    |> Map.from_struct()
    |> Enum.reject(fn {_, value} -> is_nil(value) end)
    |> Map.new()
  end

  @doc """
  Same as `Pagify.validate/2`, but raises a `Pagify.Error.InvalidParamsError` if the
  parameters are invalid.
  """
  @spec validate!(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t()) :: Pagify.t()
  def validate!(query_or_resource, map_or_pagify, opts \\ []) do
    case validate(query_or_resource, map_or_pagify, opts) do
      {:ok, pagify} ->
        pagify

      {:error, %Meta{errors: errors}} ->
        raise Pagify.Error.InvalidParamsError, errors: errors, params: map_or_pagify
    end
  end

  @doc """
  Sets the limit value of a `Pagify` struct.

      iex> set_limit(%Pagify{limit: 10, offset: 10}, 20)
      %Pagify{limit: 20, offset: 10}

      iex> set_limit(%Pagify{limit: 10, offset: 10}, "20")
      %Pagify{limit: 20, offset: 10}

  The limit will not be allowed to go below 1.

      iex> set_limit(%Pagify{}, -5)
      %Pagify{limit: 25}

  If the limit is higher than the max_limit option, the limit will be set to the max_limit.

      iex> set_limit(%Pagify{}, 102)
      %Pagify{limit: 100}
  """
  @spec set_limit(Pagify.t(), pos_integer(), Keyword.t()) :: Pagify.t()
  def set_limit(pagify, limit, opts \\ [])

  def set_limit(%Pagify{} = pagify, limit, opts) when is_integer(limit) and limit >= 1 do
    if limit <= get_option(:max_limit, opts) do
      %{pagify | limit: limit}
    else
      %{pagify | limit: get_option(:max_limit, opts)}
    end
  end

  def set_limit(%Pagify{} = pagify, limit, opts) when is_binary(limit) do
    set_limit(pagify, String.to_integer(limit), opts)
  end

  def set_limit(%Pagify{} = pagify, _, opts) do
    %{pagify | limit: get_option(:default_limit, opts)}
  end

  @doc """
  Sets the offset value of a `Pagify` struct.

      iex> set_offset(%Pagify{limit: 10, offset: 10}, 20)
      %Pagify{offset: 20, limit: 10}

      iex> set_offset(%Pagify{limit: 10, offset: 10}, "20")
      %Pagify{offset: 20, limit: 10}

  The offset will not be allowed to go below 0.

      iex> set_offset(%Pagify{}, -5)
      %Pagify{offset: 0}
  """
  @spec set_offset(Pagify.t(), non_neg_integer | binary) :: Pagify.t()
  def set_offset(%Pagify{} = pagify, offset) when is_integer(offset) do
    %{
      pagify
      | offset: max(offset, 0)
    }
  end

  def set_offset(%Pagify{} = pagify, offset) when is_binary(offset) do
    set_offset(pagify, String.to_integer(offset))
  end

  @doc """
  Sets the offset of a Pagify struct to the page depending on the limit.

  ## Examples

      iex> to_previous_offset(%Pagify{offset: 20, limit: 10})
      %Pagify{offset: 10, limit: 10}

      iex> to_previous_offset(%Pagify{offset: 5, limit: 10})
      %Pagify{offset: 0, limit: 10}

      iex> to_previous_offset(%Pagify{offset: 0, limit: 10})
      %Pagify{offset: 0, limit: 10}

      iex> to_previous_offset(%Pagify{offset: -2, limit: 10})
      %Pagify{offset: 0, limit: 10}
  """
  @spec to_previous_offset(Pagify.t()) :: Pagify.t()
  def to_previous_offset(%Pagify{offset: 0} = pagify), do: pagify

  def to_previous_offset(%Pagify{offset: offset, limit: limit} = pagify) when is_integer(limit) and is_integer(offset),
    do: %{pagify | offset: max(0, offset - limit)}

  @doc """
  Sets the offset of a Pagify struct to the next page depending on the limit.

  If the total count is given as the second argument, the offset will not be
  increased if the last page has already been reached. You can get the total
  count from the `Pagify.Meta` struct. If the Pagify has an offset beyond the total
  count, the offset will be set to the last page.

  ## Examples

      iex> to_next_offset(%Pagify{offset: 10, limit: 5})
      %Pagify{offset: 15, limit: 5}

      iex> to_next_offset(%Pagify{offset: 15, limit: 5}, 21)
      %Pagify{offset: 20, limit: 5}

      iex> to_next_offset(%Pagify{offset: 15, limit: 5}, 20)
      %Pagify{offset: 15, limit: 5}

      iex> to_next_offset(%Pagify{offset: 28, limit: 5}, 22)
      %Pagify{offset: 20, limit: 5}

      iex> to_next_offset(%Pagify{offset: -5, limit: 20})
      %Pagify{offset: 0, limit: 20}
  """
  @spec to_next_offset(Pagify.t(), non_neg_integer | nil) :: Pagify.t()
  def to_next_offset(pagify, total_count \\ nil)

  def to_next_offset(%Pagify{limit: limit, offset: offset} = pagify, _)
      when is_integer(limit) and is_integer(offset) and offset < 0,
      do: %{pagify | offset: 0}

  def to_next_offset(%Pagify{limit: limit, offset: offset} = pagify, nil) when is_integer(limit) and is_integer(offset),
    do: %{pagify | offset: offset + limit}

  def to_next_offset(%Pagify{limit: limit, offset: offset} = pagify, total_count)
      when is_integer(limit) and is_integer(offset) and is_integer(total_count) and offset >= total_count do
    %{pagify | offset: (ceil(total_count / limit) - 1) * limit}
  end

  def to_next_offset(%Pagify{limit: limit, offset: offset} = pagify, total_count)
      when is_integer(limit) and is_integer(offset) and is_integer(total_count) do
    case offset + limit do
      new_offset when new_offset >= total_count -> pagify
      new_offset -> %{pagify | offset: new_offset}
    end
  end

  @doc """
  Removes all filters from a Pagify struct.

  ## Example

      iex> reset_filters(%Pagify{filters: %{
      ...>  name: "foo",
      ...> }})
      %Pagify{filters: %{}}
  """
  @spec reset_filters(Pagify.t()) :: Pagify.t()
  def reset_filters(%Pagify{} = pagify), do: %{pagify | filters: %{}}

  @doc """
  Returns the current order direction for the given field.

  ## Examples

      iex> pagify = %Pagify{order_by: [name: :desc, age: :asc]}
      iex> current_order(pagify, :name)
      :desc
      iex> current_order(pagify, :age)
      :asc
      iex> current_order(pagify, :species)
      nil

  If the field is not an atom, the function will return `nil`.

      iex> pagify = %Pagify{order_by: [name: :desc]}
      iex> current_order(pagify, "name")
      nil

  If `Pagify.order_by` is nil, the function will return `nil`.

      iex> current_order(%Pagify{}, :name)
      nil
  """
  @spec current_order(Pagify.t(), atom) :: Ash.Sort.sort_order() | nil
  def current_order(%Pagify{order_by: nil}, _field), do: nil

  def current_order(%Pagify{order_by: order_by}, field) when is_atom(field) do
    case Enum.find(order_by, &(elem(&1, 0) == field)) do
      {_, order} -> order
      nil -> nil
    end
  end

  def current_order(_, _), do: nil

  @doc """
  Resets the order of a Pagify struct.

  ## Example

      iex> reset_order(%Pagify{order_by: [name: :asc]})
      %Pagify{order_by: nil}

  """
  @spec reset_order(Pagify.t()) :: Pagify.t()
  def reset_order(%Pagify{} = pagify), do: %{pagify | order_by: nil}

  @doc """
  Updates the `order_by` value of a `Pagify` struct.

  - If the field is not in the current `order_by` value, it will be prepended to
    the list. By default, the order direction for the field will be set to
    `:asc`.
  - If the field is already at the front of the `order_by` list, the order
    direction will be reversed.
  - If the field is already in the list, but not at the front, it will be moved
    to the front and the order direction will be set to `:asc` (or the custom
    asc direction supplied in the `:directions` option).
  - If the `:directions` option --a 2-element tuple-- is passed, the first and
    second elements will be used as custom sort declarations for ascending and
    descending, respectively.

  ## Examples

      iex> pagify = push_order(%Pagify{}, :name)
      iex> pagify.order_by
      [name: :asc]
      iex> pagify = push_order(pagify, :age)
      iex> pagify.order_by
      [age: :asc, name: :asc]
      iex> pagify = push_order(pagify, :age)
      iex> pagify.order_by
      [age: :desc, name: :asc]
      iex> pagify = push_order(pagify, :species)
      iex> pagify.order_by
      [species: :asc, age: :desc, name: :asc]
      iex> pagify = push_order(pagify, :age)
      iex> pagify.order_by
      [age: :asc, species: :asc, name: :asc]

  By default, the function toggles between `:asc` and `:desc`. You can override
  this with the `:directions` option.

      iex> directions = {:asc_nils_first, :desc_nils_last}
      iex> pagify = push_order(%Pagify{}, :ttfb, directions: directions)
      iex> pagify.order_by
      [ttfb: :asc_nils_first]
      iex> pagify = push_order(pagify, :ttfb, directions: directions)
      iex> pagify.order_by
      [ttfb: :desc_nils_last]

  This also allows you to sort in descending order initially.

      iex> directions = {:desc, :asc}
      iex> pagify = push_order(%Pagify{}, :ttfb, directions: directions)
      iex> pagify.order_by
      [ttfb: :desc]
      iex> pagify = push_order(pagify, :ttfb, directions: directions)
      iex> pagify.order_by
      [ttfb: :asc]

  If a string is passed as the second argument, it will be converted to an atom
  using `String.to_existing_atom/1`. If the atom does not exist, the `Pagify`
  struct will be returned unchanged.

      iex> pagify = push_order(%Pagify{}, "name")
      iex> pagify.order_by
      [name: :asc]
      iex> pagify = push_order(%Pagify{}, "this_atom_does_not_exist")
      iex> pagify.order_by
      nil

  If the `order_by` is either an atom or a binary, the function will return the coerced `order_by` value.

      iex> pagify = push_order(%Pagify{order_by: "author"}, :name)
      iex> pagify.order_by
      [name: :asc, author: :asc]
      iex> pagify = push_order(%Pagify{order_by: :author}, "name")
      iex> pagify.order_by
      [name: :asc, author: :asc]

  If the `:limit_order_by` option is passed, the `order_by` will be limited to the given number of fields.

      iex> pagify = push_order(%Pagify{order_by: [name: :asc, age: :asc]}, :species, limit_order_by: 1)
      iex> pagify.order_by
      [species: :asc]
  """
  @spec push_order(Pagify.t(), atom() | String.t(), Keyword.t()) :: Pagify.t()
  def push_order(pagify, field, opts \\ [])

  def push_order(%Pagify{order_by: order_by} = pagify, field, opts) when is_atom(field) do
    order_by = coerce_order_by(order_by)
    previous_index = get_index(order_by, field)
    previous_direction = get_order_direction(order_by, previous_index)

    directions = Keyword.get(opts, :directions, nil)
    new_direction = new_order_direction(previous_index, previous_direction, directions)

    order_by =
      case previous_index do
        nil ->
          [{field, new_direction} | order_by]

        idx ->
          [{field, new_direction} | List.delete_at(order_by, idx)]
      end

    order_by = limit_order_by(order_by, opts)

    %Pagify{pagify | order_by: order_by}
  end

  def push_order(pagify, field, opts) when is_binary(field) do
    push_order(pagify, String.to_existing_atom(field), opts)
  rescue
    _e in ArgumentError -> pagify
  end

  defp limit_order_by(order_by, opts) do
    case Keyword.get(opts, :limit_order_by) do
      limit when is_integer(limit) and limit > 0 -> Enum.take(order_by, limit)
      _ -> order_by
    end
  end

  @doc """
  Transforms the given `order_by` parameter into a list of tuples with
  the field and the default :asc direction.

  ## Examples

      iex> coerce_order_by(nil)
      []
      iex> coerce_order_by([])
      []
      iex> coerce_order_by(:name)
      [name: :asc]
      iex> coerce_order_by("name")
      [name: :asc]
      iex> coerce_order_by({:name, :asc})
      [name: :asc]
      iex> coerce_order_by([name: :asc, age: :desc])
      [name: :asc, age: :desc]
  """
  @spec coerce_order_by(order_by()) :: order_by()
  def coerce_order_by(nil), do: []
  def coerce_order_by([]), do: []
  def coerce_order_by(order_by) when is_atom(order_by), do: [{order_by, :asc}]

  def coerce_order_by(order_by) when is_binary(order_by), do: [{String.to_existing_atom(order_by), :asc}]

  def coerce_order_by(order_by) when is_tuple(order_by), do: [order_by]

  def coerce_order_by(order_by) when is_list(order_by) do
    Enum.map(order_by, fn
      {field, direction} when is_binary(field) -> {String.to_existing_atom(field), direction}
      {field, direction} -> {field, direction}
      field when is_binary(field) -> {String.to_existing_atom(field), :asc}
      field when is_atom(field) -> {field, :asc}
    end)
  end

  @doc """
  Finds the current index of a field in the `order_by` list.

  Following rules are applied:

  - if the `order_by` is `nil`, `nil` is returned
  - if the `order_by` is an atom or a binary, `nil` is returned
  - if the `order_by` is a tuple, `nil` is returned
  - if the `order_by` is a list, the index of the field is returned
  """
  @spec get_index(order_by(), atom()) :: non_neg_integer() | nil
  def get_index(order_by, field)
  def get_index(nil, _field), do: nil
  def get_index([], _field), do: nil
  def get_index(order_by, _field) when is_atom(order_by), do: nil
  def get_index(order_by, _field) when is_binary(order_by), do: nil
  def get_index(order_by, _field) when is_tuple(order_by), do: nil

  def get_index(order_by, field) when is_binary(field), do: get_index(order_by, String.to_existing_atom(field))

  def get_index(order_by, field) do
    Enum.find_index(order_by, fn item ->
      case item do
        {f, _} -> f == field
        f when is_binary(f) -> String.to_existing_atom(f) == field
        f -> f == field
      end
    end)
  end

  @doc """
  Returns the current order direction for the given index and `Pagify.order_by`.

  Following rules are applied:

  - if the `order_by` is `nil`, `nil` is returned
  - if the `order_by` is an atom or a binary, `:asc` is returned
  - if the `order_by` is a tuple, the second element of the tuple is returned
  - if the index is out of bounds, `nil` is returned
  - if the `order_by` is a list, the direction of the element at the given index
  is returned
  """
  @spec get_order_direction(order_by(), non_neg_integer() | nil) :: Ash.Sort.sort_order() | nil
  def get_order_direction(order_by, index)
  def get_order_direction(_, nil), do: :asc
  def get_order_direction(nil, _), do: nil
  def get_order_direction([], _), do: nil
  def get_order_direction(order_by, _) when is_atom(order_by), do: :asc
  def get_order_direction(order_by, _) when is_binary(order_by), do: :asc
  def get_order_direction(order_by, _) when is_tuple(order_by), do: Enum.at(order_by, 1)

  def get_order_direction(order_by, index) do
    case Enum.at(order_by, index, :asc) do
      {_, direction} -> direction
      _ -> :asc
    end
  end

  defguardp is_direction(value)
            when value in [
                   :asc,
                   :asc_nils_first,
                   :desc,
                   :desc_nils_last
                 ]

  defguardp is_asc_direction(value)
            when value in [
                   :asc,
                   :asc_nils_first
                 ]

  defguardp is_desc_direction(value)
            when value in [
                   :desc,
                   :desc_nils_last
                 ]

  defp new_order_direction(0, current_direction, nil), do: reverse_direction(current_direction)

  defp new_order_direction(0, current_direction, {_asc, desc})
       when is_asc_direction(current_direction) and is_desc_direction(desc),
       do: desc

  defp new_order_direction(0, current_direction, {desc, _asc})
       when is_asc_direction(current_direction) and is_desc_direction(desc),
       do: desc

  defp new_order_direction(0, current_direction, {asc, _desc})
       when is_desc_direction(current_direction) and is_asc_direction(asc),
       do: asc

  defp new_order_direction(0, current_direction, {_desc, asc})
       when is_desc_direction(current_direction) and is_asc_direction(asc),
       do: asc

  defp new_order_direction(0, _current_direction, directions) do
    raise Pagify.Error.InvalidDirectionsError, directions: directions
  end

  defp new_order_direction(_, _, nil), do: :asc
  defp new_order_direction(_, _, {asc, _desc}) when is_direction(asc), do: asc

  defp new_order_direction(_, _, directions) do
    raise Pagify.Error.InvalidDirectionsError, directions: directions
  end

  defp reverse_direction(:asc), do: :desc
  defp reverse_direction(:asc_nils_first), do: :desc_nils_last
  defp reverse_direction(:desc), do: :asc
  defp reverse_direction(:desc_nils_last), do: :asc_nils_first

  @doc """
  Returns the option with the given key.

  The look-up order is:

  1. the keyword list passed as the second argument
  2. the Ash.Resource resource, if the passed list includes the `:for` option
  3. the application environment
  4. the Pagify default value if defined
  5. the default passed as the last argument
  """
  @spec get_option(atom(), Keyword.t(), any()) :: any()
  def get_option(key, opts \\ [], default \\ nil) do
    with nil <- opts[key],
         nil <- resource_option(opts[:for], key),
         nil <- global_option(key) do
      Keyword.get(@default_opts, key, default)
    end
  end

  defp resource_option(resource, key) when is_atom(resource) and resource != nil and key in [:default_limit] do
    if Keyword.has_key?(resource.__info__(:functions), key) do
      apply(resource, key, [])
    end
  end

  defp resource_option(resource, key) when is_atom(resource) and resource != nil and key == :default_order do
    resource |> Info.preparations() |> resource_preparation_sort()
  end

  defp resource_option(_, _), do: nil

  defp resource_preparation_sort(preparations, default \\ nil)
  defp resource_preparation_sort([], default), do: default

  defp resource_preparation_sort([%Ash.Resource.Preparation{preparation: {_, [options: [sort: sort]]}} | _rest], _default)
       when is_list(sort) do
    sort
  end

  defp resource_preparation_sort([_ | rest], default) do
    resource_preparation_sort(rest, default)
  end

  defp global_option(key) when is_atom(key) do
    :data_aggregator
    |> Application.get_env(:pagify, [])
    |> Keyword.get(key, nil)
  end
end
