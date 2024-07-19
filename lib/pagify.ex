defmodule Pagify do
  @moduledoc """
  Pagify is an Elixir library designed to easily apply full-text search, scoping, filtering,
  ordering, and pagination to your `Ash` queries.

  It takes concepts from `Flop`, `Flop.Phoenix`, `Ash` and `AshPhoenix.FilterForm` and
  combines them into a single library.

  ## Features

  - **Full-text search**: Pagify supports full-text search using the `tsvector` column in
    PostgreSQL.
  - **Offset-based pagination**: Pagify uses `OFFSET` and `LIMIT` to paginate your queries.
  - **Scoping**: Apply predefined filters to your queries using a simple map syntax.
  - **Filtering**: Apply user-input filters to your queries using a simple map syntax. Allows
    complex data filtering using multiple conditions, operators, and fields. Also incooperates
    with `AshPhoenix.FilterForm` to provide a simple way to build complex filter user interfaces.
  - **Sorting**: Sort your queries by multiple fields and any directions.
  - **UI helpers and URL builders**: Pagify provides a `Pagify.Meta` struct with information about
    the current page, total pages, and more. This information can be used to build pagination links
    in your UI. Further, `Pagify` provides the `Pagify.Components` module with a table and pagination
    component to easily build sortable tables and pagination links in your Phoenix LiveView. The
    `Pagify.Components` module also provides a URL builder to generate URLs with the correct
    full-text search, pagination, scoping, filtering, and sorting parameters.

  ## Installation

  > #### Note {: .info}
  >
  > The following instructions are for Ash 2.13. Ash 3.0 and later versions are not yet supported.

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

  If you want to include tests, you can copy the `test/pagify` directory as well. In this case, you
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
        replace_invalid_params?: true,
        pagify_scopes: %{
          role: [
            %{name: :all, filter: nil},
            %{name: :admin, filter: %{role: "admin"}},
            %{name: :user, filter: %{role: "user"}}
          ]
        },
        reset_on_filter?: true

  See `t:Pagify.option/0` for a description of all available options.

  ## Usage

  > #### Resource pagination macro {: .info}
  >
  > As of Ash >= 3.0 you do not need to use the `pagination` macro in your default read actions as
  > default read actions are now paginatable with keyset and offset pagination
  > (but pagination is not required)

  You need to add the pagination macro call to the action of the resource that you
  want to be paginated. The macro call is used to set the default limit, offset and
  other options for the pagination.

  Furthermore, you can define scopes in the resource module. Scopes are predefined
  filters that can be applied to the query.

  If you want to use full-text search in your resource, you need to implement the
  `full_text_search` and `tsvector` calculations as described below.

  ```elixir
  defmodule YourApp.Resource.Post
    # only required if you want to implement full-text search
    require Ash.Query

    @default_limit 15
    def default_limit, do: @default_limit

    @pagify_scopes %{
      role: [
        %{name: :all, filter: nil},
        %{name: :admin, filter: %{author: "John"}},
        %{name: :user, filter: %{author: "Doe"}}
      ]
    }
    def pagify_scopes, do: @pagify_scopes

    actions do
      read :read do
        #...
        pagination offset?: true,
                  default_limit: @default_limit,
                  countable: true,
                  required?: false
      end
    end

    calculations do
      # on the fly tsvector generation
      calculate :full_text_search,
                :boolean,
                expr(fragment("(to_tsvector(?) @@ ?)", field, ^arg(:search))) do
        argument :search, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
      end

      # or with a generated tsvector
      calculate :full_text_search,
                :boolean,
                expr(fragment("(? @@ ?)", generated_tsvector, ^arg(:search))) do
        argument :search, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
      end

      # mandatory so that you can search with Ash.Query.filter(Post, full_text_search(search: expr(tsquery(search: "post 1"))))
      calculate :tsquery,
                AshPostgres.Tsquery,
                expr(fragment("to_tsquery(?)", ^arg(:search))) do
        argument :search, :string, allow_expr?: true, allow_nil?: false
      end

      # or with dictionary and unaccent (needs unaccent extension installed)
      calculate :tsquery,
                AshPostgres.Tsquery,
                expr(fragment("to_tsquery('simple', unaccent(?))", ^arg(:search))) do
        argument :search, :string, allow_expr?: true, allow_nil?: false
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

  ## Full-text search

  We allow full-text search using the `tsvector` column in PostgreSQL. To enable full-text search,
  you need to implement the `full_text_search` and `tsquery` calculations in your resource module.

  First, you need to provide the `tsquery` calculation in the resource module. The calculation should
  always look like this:

  ```elixir
    # mandatory so that you can search with Ash.Query.filter(Post, full_text_search(search: expr(tsquery(search: "post 1"))))
    calculate :tsquery,
              AshPostgres.Tsquery,
              expr(fragment("to_tsquery(?)", ^arg(:search))) do
      argument :search, :string, allow_expr?: true, allow_nil?: false
    end

    # or with dictionary and unaccent (needs unaccent extension installed)
    calculate :tsquery,
              AshPostgres.Tsquery,
              expr(fragment("to_tsquery('simple', unaccent(?))", ^arg(:search))) do
      argument :search, :string, allow_expr?: true, allow_nil?: false
    end
  ```

  Afterwards, you need to provide the `full_text_search` calculation. This calculation should look as
  following, wherease you can replace the `field` parameter with your field you want to include
  in the full-text search (or you a generated tsvector column):

  ```elixir
    calculate :full_text_search,
              :boolean,
              expr(fragment("(to_tsvector(?) @@ ?)", field, ^arg(:search))) do
      argument :search, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
    end
  ```

  Or if you want to use a generated tsvector column, you can replace the fields
  part with the name of your generated tsvector column:

  ```elixir
    calculate :full_text_search,
              :boolean,
              expr(fragment("(? @@ ?)", generated_tsvector, ^arg(:search))) do
      argument :search, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
    end
  ```

  Once configured, you can use the `search` parameter to apply full-text search.

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
  full-text search, pagination, scoping, filtering, and sorting parameters to it.
  You can use verified routes, route helpers, or custom path builder functions.
  You'll find explanations for the different formats in the documentation for
  `Pagify.Components.build_path/3`.

  Note that the field attribute in the `:col` slot is optional. If set and the
  corresponding field in the resource is defined as sortable, the table header for
  that column will be interactive, allowing users to sort by that column. However,
  if the field isn't defined as sortable, or if the field attribute is omitted, or
  set to `nil` or `false`, the table header will not be clickable.

  You also have the option to pass a `Phoenix.LiveView.JS` command instead of or
  in addition to a path. For more details, please refer to the component
  documentation.

  ## Parameter format

  The Pagify library requires parameters to be provided in a specific format as a map.
  This map can be translated into a URL query parameter string, typically for use in a
  web framework like Phoenix.

  The following parameters are encoded as strings and handled by the library:

  - `search` - A string to search for in the full-text search column or in the searchable fields.
  - `limit` - The number of records to return.
  - `offset` - The number of records to skip.
  - `scopes` - A map of predefined filters to apply to the query.
  - `filter_form` - A map of filters provided by the `Pagify.FilterForm` module.
  - `order_by` - A list of fields to order by.

  ## Search

  You can search for a string in a full-text search column.

      %{search: "John"}

  This translates to the following query parameter string:

  ```URL
  ?search=John
  ```

  ## Pagination

  You can specify an offset to start from and a limit to the number of results.

      %{offset: 100, limit: 20}

  This translates to the following query parameter string:

  ```URL
  ?offset=100&limit=20
  ```

  ## Scoping

  To apply predefined filters to a query, you can set the `:scopes` parameter. `:scopes`
  should be a map of predefined filters (maps) available in your resource. The filter name
  is used to look up the predefined filter. If the filter is found, it is applied to
  the query. If the filter is not found, an error is raised.

      iex> params = %{scopes: %{role: :admin}}
      iex> {:ok, pagify} = Pagify.validate(Post, params)
      iex> pagify.scopes
      %{role: :admin, status: :all}

  This translates to the following query parameter string:

  ```URL
  ?scopes[role]=admin
  ```

  ## Filter forms

  Filter forms can be passed as a map of filter conditions. Usually, this map is generated
  by a filter form component using the `Pagify.FilterForm` module. `Pagify.FilterForm.params_for_query/2`
  can be used to convert the form filter map into a query map.

      iex> params = %{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}}
      iex> {:ok, {results, meta}} = Pagify.validate_and_run(Post, params)
      iex> meta.total_count
      1
      iex> [post] = results
      iex> post.name
      "Post 1"

  This translates to the following query parameter string:

  ```URL
  ?filter_form[name][eq]=Post%201
  ```

  Check the `AshPhoenix.FilterForm` documentation for more information.
  See `Ash.Query.filter/2` for a list of all available filter operators.

  ## Ordering

  To add an ordering clause to a query, you need to set the `:order_by`
  parameter. `:order_by` should be a list of fields, aggregates, or calculations
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
  ?order_by=[]name&oder_by[]=--author
  ```

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
  def list_posts(%{} = params, opts \\\\ [], %User{} = current_user) do
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
  alias Pagify.FilterForm
  alias Pagify.Meta
  alias Pagify.Misc
  alias Pagify.Validation

  require Ash.Query
  require Logger

  @default_opts [
    default_limit: 25,
    max_limit: 100,
    replace_invalid_params?: false,
    pagify_scopes: %{},
    reset_on_filter?: true
  ]
  @default_opts_keys Enum.map(@default_opts, fn {k, _} -> k end)

  @internal_opts [
    :__compiled_pagify_scopes,
    :__compiled_pagify_default_scopes,
    :for,
    :full_text_search
  ]
  @resource_options [:default_limit, :pagify_scopes]

  defstruct limit: nil,
            offset: nil,
            scopes: nil,
            filter_form: nil,
            filters: nil,
            order_by: nil,
            search: nil

  @typedoc """
  These options can be passed to most functions or configured via the
  application environment.

  ## Options

  Default pagify options in addition to the ones provided by the
  `Ash.read/2` function. These options are used to configure the
  pagination behavior.

  - `:default_limit` - The default number of records to return. Defaults to 25.
    Can be overridden by the resource's `default_limit` function.
  - `:max_limit` - The maximum number of records that can be returned. Defaults
    to 100.
  - `:replace_invalid_params?` - If set to `true`, invalid parameters will be
    replaced with the default value. If set to `false`, invalid parameters
    will result in an error. Defaults to `false`.
  - `:pagify_scopes` - A map of predefined filters to apply to the query. Each map
    entry itself is a group (list) of `t:Pagify.scope/0` entries.
  - `:reset_on_filter?` - If set to `true`, the offset will be reset to 0 when
    a filter is applied. Defaults to `true`.

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
          | {pagify_scopes :: map()}
          | {reset_on_filter? :: boolean()}

  @typedoc """
  A scope is a predefined filter that is merged with the user-provided filters.

  Scope definitions live in the resource provided `pagify_scopes` function or in
  the provided `t:Pagify.option/0`. Contrary to user-provided filters, scope filters
  are not parsed as user input and are not validated as such. However, they are
  validated in the `Pagify.validate_and_run/4` context. User-provided parameters are
  used to lookup the scope filter. If the scope filter is found, it is applied to the query.
  If the scope filter is not found, an error is raised.

  ## Fields

  - `:name` - The name of the filter for the scope.
  - `:filter` - The filter to apply to the query.
  - `:default?` - If set to `true`, the scope is applied by default.
  """
  @type scope ::
          {name :: atom()}
          | {filter :: Ash.Filter.t()}
          | {default? :: boolean()}

  @typedoc """
  Valid order_by types for the `t:Pagify.t/0` struct.
  """
  @type order_by :: [atom() | String.t() | {atom(), Ash.Sort.sort_order()} | [String.t()]] | nil

  @typedoc """
  Represents the query parameters for full-text search, scoping, filtering, ordering and pagination.

  ### Fields

  - `limit`, `offset`: Used for offset-based pagination.
  - `scopes`: A map of user provided scopes to apply to the query. Scopes are internally translated to
    predefined filters and merged into the query enginge.
  - `filter_form`: A map of filters provided by `AshPhoenix.FilterForm` module. These filters are meant
    to be used in user interfaces.
  - `filters`: A map of manually provided filters to apply to the query. These filters must be provided in
    the map syntax and are meant to be used in business logic context (see `Ash.Filter` for examples).
  - `order_by`: A list of fields to order by (see `Ash.Sort.parse_input/3` for all available orders).
  - `search`: A string to search for in the full-text search column.
  """
  @type t :: %__MODULE__{
          limit: pos_integer() | nil,
          offset: non_neg_integer() | nil,
          scopes: map() | nil,
          filter_form: map() | nil,
          filters: map() | nil,
          order_by: order_by(),
          search: String.t() | nil
        }

  @doc """
  Adds clauses for full-text search, scoping, filtering, ordering and pagination to an `t:Ash.Query.t/0`
  or `t:Ash.Resource.t/0` from the given `t:Pagify.t/0` parameters and `t:Keyword.t/0` options.

  The keyword list `opts` is used to pass additional options to the query engine.
  It shoud conform to the list of valid options at `Ash.read/2`. Furthermore
  the `t:Pagify.option/0` library options are supported.

  We take the keyword list `opts` and return a keyword list callback according to
  `Ash.read/2` but with the __:query__ keyword also within the list.

  - `Paigfy.scopes` are used to apply predefined filters to the query.
  - `Pagify.filter_form` is used to apply filters generated by the `AshPhoenix.FilterForm` module.
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

  Scoping only:

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{scopes: %{role: :admin}}
      iex> [page, {:query, query}] = parse(Post, pagify)
      iex> page
      {:page, [count: true, offset: 0, limit: 15]}
      iex> query
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<author == "John">>

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec parse(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) :: Keyword.t()
  def parse(query_or_resource, pagify, opts \\ [])

  def parse(%Ash.Query{} = q, %Pagify{} = pagify, opts) do
    opts = Keyword.put(opts, :query, query(q, pagify, opts))
    paginate(q, pagify, opts)
  end

  def parse(r, %Pagify{} = pagify, opts) when is_atom(r) and r != nil do
    parse(Ash.Query.new(r), pagify, opts)
  end

  @doc """
  Returns an `t:Ash.Page.Offset.t/0` struct from the given `t:Ash.Query.t/0` or `t:Ash.Resource.t/0`
  with the given `t:Pagify.t/0` parameters and `t:Keyword.t/0` options.

  The `opts` keyword list is used to pass additional options to the query engine.
  It should conform to the list of valid options at `Ash.read/2`.

  - `Paigfy.scopes` are used to apply predefined filters to the query.
  - `Pagify.filter_form` is used to apply filters generated by the `AshPhoenix.FilterForm` module.
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

  Or with scopes:

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{scopes: %{role: :admin}}
      iex> %Ash.Page.Offset{count: count} = Pagify.all(Post, pagify)
      iex> count
      1

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
    opts = parse(q, pagify, opts)
    opts = remove_pagify_opts(opts)

    case Keyword.get(opts, :action) do
      nil ->
        r.read!(opts)

      action ->
        {:ok, page} = apply(r, action, [args, opts])
        page
    end
  end

  def all(r, %Pagify{} = pagify, opts, args) when is_atom(r) and r != nil do
    all(Ash.Query.new(r), pagify, opts, args)
  end

  defp remove_pagify_opts(opts) do
    Enum.filter(opts, fn {k, _} ->
      !Enum.member?(@default_opts_keys, k) and !Enum.member?(@internal_opts, k)
    end)
  end

  @doc """
  Returns the total count of entries matching the full-text search, filters, filter_form,
  and scopes conditions in the given `t:Ash.Query.t/0` or `t:Ash.Resource.t/0` with the
  given `t:Pagify.t/0` parameters and `t:Keyword.t/0` options.

  The pagination and ordering options are disregarded.

      iex> alias Pagify.Factory.Post
      iex> Pagify.count(Post, %Pagify{})
      3

  You can override the default query by passing the `:count_query` option. This
  doesn't make a lot of sense when you use `count/3` directly, but allows you to
  optimize the count query when you use one of the `run/4`,
  `validate_and_run/4` and `validate_and_run!/4` functions.

      query = some expensive query
      count_query = Ash.Query.new(Post)
      Pagify.count(Post, %Pagify{}, count_query: count_query)

  The full-text search and various filter parameters of the given Pagify are applied
  to the custom count query.

  If for some reason you already have the count, you can pass it as the `:count`
  option.

      count(query, %Pagify{}, count: 42, for: Post)

  If you pass both the `:count` and the `:count_query` options, the `:count`
  option will take precedence.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine. Or you can use `Pagify.validate_and_run/4` or
  `Pagify.validate_and_run!/4` instead of this function.
  """
  @spec count(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) ::
          non_neg_integer()
  def count(query_or_resource, pagify, opts \\ [])

  def count(%Ash.Query{resource: r} = q, %Pagify{} = pagify, opts) do
    if count = opts[:count] do
      count
    else
      q =
        if count_query = opts[:count_query] do
          count_query
        else
          query(q, pagify, Keyword.put_new(opts, :for, r))
        end

      opts = Keyword.delete(opts, :count_query)
      opts = Keyword.delete(opts, :count)

      Ash.count!(q, opts)
    end
  end

  def count(r, %Pagify{} = pagify, opts) when is_atom(r) and r != nil do
    count(Ash.Query.new(r), pagify, opts)
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
    run(Ash.Query.new(r), pagify, opts, args)
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

  Or with scopes:

      iex> alias Pagify.Factory.Post
      iex> {:ok, {[%Post{}], %Pagify.Meta{}}} = Pagify.validate_and_run(Post, %Pagify{scopes: %{role: :user}})

  ## Options

  The keyword list `opts` is used to pass additional options to the query engine.
  It shoud conform to the list of valid options at `Ash.read/2`. Furthermore
  the `t:Pagify.option/0` library options are supported.
  """
  @spec validate_and_run(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t(), any()) ::
          {:ok, {[Ash.Resource.record()], Meta.t()}} | {:error, Meta.t()}
  def validate_and_run(query_or_resource, map_or_pagify, opts \\ [], args \\ nil) do
    opts =
      query_or_resource
      |> Misc.maybe_put_compiled_pagify_scopes(opts)
      |> Keyword.put_new(:for, get_resource(query_or_resource))

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
    opts =
      query_or_resource
      |> Misc.maybe_put_compiled_pagify_scopes(opts)
      |> Keyword.put_new(:for, get_resource(query_or_resource))

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
        current_page: 2,
        default_scopes: %{status: :all},
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
    current_search = pagify.search

    {has_previous_page?, previous_offset} = get_previous(current_offset, page_size)
    {has_next_page?, next_offset} = get_next(current_offset, page_size, total_count)

    resource = get_resource(page)

    default_scopes = get_default_scopes(resource, opts)

    %Meta{
      current_limit: page_size,
      current_offset: current_offset,
      current_page: current_page,
      current_search: current_search,
      default_scopes: default_scopes,
      has_next_page?: has_next_page?,
      has_previous_page?: has_previous_page?,
      next_offset: next_offset,
      opts: remove_pagify_opts(opts),
      pagify: pagify,
      previous_offset: previous_offset,
      resource: resource,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  defp get_resource(%Ash.Page.Offset{rerun: {original_query, _}}), do: original_query.resource
  defp get_resource(%Ash.Query{resource: r}), do: r
  defp get_resource(resource) when is_atom(resource) and resource != nil, do: resource

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

  defp get_default_scopes(resource, opts) do
    opts = Misc.maybe_put_compiled_pagify_scopes(resource, opts)
    Keyword.get(opts, :__compiled_pagify_default_scopes)
  end

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
  Adds clauses for full-text search, scoping, filtering and ordering to an
  `t:Ash.Query.t/0` from the given `t:Pagify.t/0` parameter.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> q = Ash.Query.new(Post)
      iex> pagify = %Pagify{filters: %{name: "John"}, order_by: ["name"]}
      iex> query(q, pagify)
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "John">, sort: [{"name", :asc}]>
  """
  @spec query(Ash.Query.t(), Pagify.t(), Keyword.t()) :: Ash.Query.t()
  def query(%Ash.Query{} = q, %Pagify{} = pagify, opts \\ []) do
    q
    |> search(pagify, opts)
    |> scope(pagify, opts)
    |> filter_form(pagify)
    |> filter(pagify)
    |> order_by(pagify)
  end

  ## Search

  @doc """
  Applies the `search` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. Pagify allows you to perform full-text searches on resources. It uses the
  built-in [PostgreSQL full-text search functionality](https://www.postgresql.org/docs/current/textsearch.html).

  ```elixir
    # on the fly tsvector generation
    calculate :full_text_search,
              :boolean,
              expr(fragment("(to_tsvector(?) @@ ?)", field, ^arg(:search))) do
      argument :search, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
    end

    # or with a generated tsvector
    calculate :full_text_search,
              :boolean,
              expr(fragment("(? @@ ?)", generated_tsvector, ^arg(:search))) do
      argument :search, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
    end

    calculate :tsquery,
              AshPostgres.Tsquery,
              expr(fragment("to_tsquery(?)", ^arg(:search))) do
      argument :search, :string, allow_expr?: true, allow_nil?: false
    end

    # or with dictionary and unaccent (needs extension installed)
    calculate :tsquery,
              AshPostgres.Tsquery,
              expr(fragment("to_tsquery('simple', unaccent(?))", ^arg(:search))) do
      argument :search, :string, allow_expr?: true, allow_nil?: false
    end
  ```

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec search(Ash.Query.t(), Pagify.t(), Keyword.t()) :: Ash.Query.t()
  def search(q, pagify, opts \\ [])

  def search(%Ash.Query{} = q, %Pagify{search: nil}, _opts), do: q
  def search(%Ash.Query{} = q, %Pagify{search: ""}, _opts), do: q

  def search(%Ash.Query{} = q, %Pagify{search: search} = pagify, opts) do
    tsquery = Pagify.Tsearch.tsquery(search, opts)
    tsquery = Ash.Query.expr(tsquery(search: tsquery))
    tsvector = Pagify.Tsearch.tsvector(opts)

    q
    |> Ash.Query.filter(full_text_search(tsvector: tsvector, tsquery: tsquery))
    |> maybe_put_ts_rank(pagify, tsvector, tsquery)
  end

  defp maybe_put_ts_rank(%Ash.Query{} = q, %Pagify{order_by: order_by}, tsvector, tsquery)
       when is_nil(order_by) or order_by == [] do
    Ash.Query.sort(q, full_text_search_rank: {:desc, %{tsvector: tsvector, tsquery: tsquery}})
  end

  defp maybe_put_ts_rank(%Ash.Query{} = q, _, _, _), do: q

  ## Scope

  @doc """
  Applies the `scopes` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. At this stage we assume that the scopes are already
  compiled and validated. Further, default scopes are loaded into the Pagify struct.

  For a completed list of filter operators, see `Ash.Filter`.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> q = Ash.Query.new(Post)
      iex> pagify = %Pagify{scopes: %{status: :active}}
      iex> scope(q, pagify)
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<age < \e[36m10\e[0m>>
  """
  @spec scope(Ash.Query.t(), Pagify.t(), Keyword.t()) :: Ash.Query.t()
  def scope(q, pagify, opts \\ [])

  def scope(%Ash.Query{} = q, %Pagify{scopes: nil}, _), do: q

  def scope(%Ash.Query{resource: resource} = query, %Pagify{scopes: scopes}, opts) when is_map(scopes) do
    opts = Misc.maybe_put_compiled_pagify_scopes(resource, opts)
    compiled_scopes = Keyword.get(opts, :__compiled_pagify_scopes)

    Enum.reduce(scopes, query, fn {group, name}, acc ->
      apply_scope(acc, compiled_scopes, group, name)
    end)
  end

  defp apply_scope(query, compiled_scopes, group, name) do
    group_scopes = get_group_scopes(compiled_scopes, group)
    scope = find_scope(group_scopes, group, name)

    if scope.filter == nil do
      query
    else
      Ash.Query.filter(query, ^scope.filter)
    end
  end

  defp get_group_scopes(compiled_scopes, group) do
    case Map.get(compiled_scopes, group) do
      nil -> raise ArgumentError, "Group `#{group}` not found"
      group_scopes -> group_scopes
    end
  end

  defp find_scope(group_scopes, group, name) do
    Enum.find(group_scopes, fn scope -> scope.name == name end) ||
      raise ArgumentError, "Scope `#{name}` not found in group `#{group}`"
  end

  ## Filter Form

  @doc """
  Applies the `filter_form` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. See `AshPhoenix.FilterForm` for more information.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> q = Ash.Query.new(Post)
      iex> pagify = %Pagify{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}}
      iex> filter_form(q, pagify)
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "Post 1">>
  """
  @spec filter_form(Ash.Query.t(), Pagify.t()) :: Ash.Query.t()
  def filter_form(q, pagify)
  def filter_form(%Ash.Query{} = q, %Pagify{filter_form: nil}), do: q

  def filter_form(%Ash.Query{} = q, %Pagify{filter_form: %{} = filter_form}) when filter_form == %{}, do: q

  def filter_form(%Ash.Query{resource: r} = q, %Pagify{filter_form: filter_form}) do
    filter_map = filter_form_to_filter_map(r, filter_form)
    Ash.Query.filter(q, ^filter_map)
  end

  def filter_form(%Ash.Query{} = q, _), do: q

  ## Filter

  @doc """
  Applies the `filter` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. See `Ash.Query.filter/2` for more information.

  For a completed list of filter operators, see `Ash.Filter`.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{filters: %{name: "foo"}}
        iex> filter(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">>

  Or multiple filters:

        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{filters: %{name: "foo", id: "1"}}
        iex> filter(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<id == "1" and name == "foo">>

  Or by relation:

        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{filters: %{comments: %{body: "foo"}}}
        iex> filter(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<comments.body == "foo">>
  """
  @spec filter(Ash.Query.t(), Pagify.t()) :: Ash.Query.t()
  def filter(q, pagify)

  def filter(%Ash.Query{} = q, %Pagify{filters: nil}), do: q
  def filter(%Ash.Query{} = q, %Pagify{filters: []}), do: q

  def filter(%Ash.Query{} = q, %Pagify{filters: filters}) do
    Ash.Query.filter(q, ^filters)
  end

  def filter(%Ash.Query{} = q, _), do: q

  ## Ordering

  @doc """
  Applies the `order_by` parameter of a `t:Pagify.t/0` to an `t:Ash.Query.t/0`.

  Used by `Pagify.query/2`. See `Ash.Query.sort/3` for more information.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{order_by: ["name"]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [{"name", :asc}]>

  Or descending order nulls last:
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{order_by: [name: :desc_nils_last]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [name: :desc_nils_last]>

  Or multiple fields:
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{order_by: ["name", "id"]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [{"name", :asc}, {"id", :asc}]>

  Or by calculation:
        iex> alias Pagify.Factory.Post
        iex> q = Ash.Query.new(Post)
        iex> pagify = %Pagify{order_by: ["comments_count"]}
        iex> order_by(q, pagify)
        #Ash.Query<resource: Pagify.Factory.Post, sort: [comments_count: :asc]>
  """
  @spec order_by(Ash.Query.t(), Pagify.t()) :: Ash.Query.t()
  def order_by(q, pagify)

  def order_by(%Ash.Query{} = q, %Pagify{order_by: nil}), do: q
  def order_by(%Ash.Query{} = q, %Pagify{order_by: []}), do: q

  def order_by(%Ash.Query{} = q, %Pagify{order_by: order_by}) do
    Ash.Query.sort(q, order_by)
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
    paginate(Ash.Query.new(r), pagify, opts)
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
      {:ok, %Pagify{limit: 10, offset: 20, scopes: %{status: :all}}}

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
  used for scoping, ordering and filtering. The function will also apply the
  default_limit and scoping if the resource provides one.

  > #### Resource pagination macro {: .info}
  >
  > As of Ash >= 3.0 you do not need to use the `pagination` macro in your default read actions as
  > default read actions are now paginatable with keyset and offset pagination
  > (but pagination is not required)

  You need to add the pagination macro call to the action of the resource that you
  want to be paginated. The macro call is used to set the default limit, offset and
  other options for the pagination.

  Furthermore, you can define scopes in the resource module. Scopes are predefined
  filters that can be applied to the query.

      defmodule Your.Ash.Resource
        @default_limit 15
        def default_limit, do: @default_limit

        @pagify_scopes %{
          role: [
            %{name: :all, filter: nil},
            %{name: :admin, filter: %{author: "John"}},
            %{name: :user, filter: %{author: "Doe"}}
          ]
        }
        def pagify_scopes, do: @pagify_scopes

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
  Same as `Pagify.validate/2`, but raises a `Pagify.Error.Query.InvalidParamsError` if the
  parameters are invalid.
  """
  @spec validate!(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t()) :: Pagify.t()
  def validate!(query_or_resource, map_or_pagify, opts \\ []) do
    case validate(query_or_resource, map_or_pagify, opts) do
      {:ok, pagify} ->
        pagify

      {:error, %Meta{errors: errors}} ->
        raise Pagify.Error.Query.InvalidParamsError, errors: errors, params: map_or_pagify
    end
  end

  @doc """
  Validates the given query or resource and pagify parameters and returns a
  validated query.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{limit: 10, offset: 20, order_by: ["name"], filters: %{name: "foo"}}
      iex> validated_query(Post, pagify)
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">, sort: [name: :asc]>
  """
  @spec validated_query(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t()) ::
          Ash.Query.t()
  def validated_query(query_or_resource, map_or_pagify, opts \\ [])

  def validated_query(%Ash.Query{} = q, map_or_pagify, opts) do
    pagify = validate!(q, map_or_pagify, opts)
    query(q, pagify, opts)
  end

  def validated_query(r, map_or_pagify, opts) when is_atom(r) and r != nil do
    validated_query(Ash.Query.new(r), map_or_pagify, opts)
  end

  @doc """
  Sets the tsvector value in the full_text_search clause of the `Keyword.t` opts parameter.

  If the full_text_search clause does not exist, it will be created. If the tsvector
  value already exists, it will be updated.

  # Examples

      iex> set_tsvector("bar", [full_text_search: [tsvector: "foo"]])
      [full_text_search: [tsvector: "bar"]]

      iex> set_tsvector("bar")
      [full_text_search: [tsvector: "bar"]]

      iex> set_tsvector("foo", [full_text_search: [tsvector: "foo"]])
      [full_text_search: [tsvector: "foo"]]
  """
  def set_tsvector(tsvector, opts \\ []) do
    Keyword.update(
      opts,
      :full_text_search,
      [tsvector: tsvector],
      fn full_text_search ->
        Keyword.put(full_text_search, :tsvector, tsvector)
      end
    )
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
  Sets the search of a Pagify struct.

  If the reset option is set to false, the offset will not be reset to 0.

  ## Examples

      iex> set_search(%Pagify{offset: 10}, "term")
      %Pagify{search: "term"}

      iex> set_search(%Pagify{offset: 10, search: "old"}, "new")
      %Pagify{search: "new"}

      iex> set_search(%Pagify{offset: 10, search: "old"}, nil)
      %Pagify{search: nil}

  Or without reset offset:

      iex> set_search(%Pagify{offset: 10}, "term", reset_on_filter?: false)
      %Pagify{search: "term", offset: 10}
  """
  @spec set_search(Pagify.t(), String.t() | nil, Keyword.t()) :: Pagify.t()
  def set_search(pagify, search, opts \\ [])

  def set_search(%Pagify{} = pagify, search, opts) do
    pagify = %{pagify | search: search}

    reset_on_filter = get_option(:reset_on_filter?, opts, true)

    if reset_on_filter do
      %{pagify | offset: nil}
    else
      pagify
    end
  end

  @doc """
  Sets the scope of a Pagify struct.

  If the scope already exists, it will be replaced with the new value. If the
  scope does not exist, it will be added to the scopes map.

  If the reset option is set to false, the offset will not be reset to 0.

  ## Examples

      iex> set_scope(%Pagify{offset: 10, scopes: %{status: :active}}, %{status: :inactive})
      %Pagify{scopes: %{status: :inactive}}

      iex> set_scope(%Pagify{offset: 10, scopes: %{status: :active}}, %{status: :active})
      %Pagify{scopes: %{status: :active}}

  Or add a new scope:

      iex> set_scope(%Pagify{offset: 10, scopes: %{role: :admin}}, %{status: :active})
      %Pagify{scopes: %{status: :active, role: :admin}}

      iex> set_scope(%Pagify{}, %{role: :admin})
      %Pagify{scopes: %{role: :admin}}

  Or without reset offset:

      iex> set_scope(%Pagify{offset: 10}, %{status: :active}, reset_on_filter?: false)
      %Pagify{scopes: %{status: :active}, offset: 10}
  """
  @spec set_scope(Pagify.t(), map(), Keyword.t()) :: Pagify.t()
  def set_scope(pagify, scope, opts \\ [])

  def set_scope(%Pagify{} = pagify, scope, opts) do
    scopes = pagify.scopes || %{}
    pagify = %{pagify | scopes: Map.merge(scopes, scope)}

    reset_on_filter = get_option(:reset_on_filter?, opts, true)

    if reset_on_filter do
      %{pagify | offset: nil}
    else
      pagify
    end
  end

  @doc """
  Helper function to check if a scope is active in a Pagify struct.

  ## Examples

      iex> active_scope?(%Pagify{scopes: %{status: :active}}, %{status: :active})
      true

      iex> active_scope?(%Pagify{scopes: %{status: :active}}, %{status: :inactive})
      false

      iex> active_scope?(%Pagify{scopes: %{status: :active}}, %{role: :admin})
      false

      iex> active_scope?(%Pagify{}, %{role: :admin})
      false
  """
  @spec active_scope?(Pagify.t(), map()) :: boolean
  def active_scope?(%Pagify{scopes: nil}, _), do: false

  def active_scope?(%Pagify{scopes: scopes}, scope) do
    group = scope |> Map.keys() |> hd()
    name = scope |> Map.values() |> hd()

    case Map.get(scopes, group) do
      nil -> false
      active -> active == name
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
  Removes all filter_form from a Pagify struct.

  ## Example

      iex> reset_filter_form(%Pagify{
      ...>   filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}
      ...> })

      %Pagify{filter_form: %{}}
  """
  @spec reset_filter_form(Pagify.t()) :: Pagify.t()
  def reset_filter_form(%Pagify{} = pagify), do: %{pagify | filter_form: %{}}

  @doc """
  Updates the filter form of a Pagify.Meta struct.

  If the filter already exists, it will be replaced with the new value. If the
  filter does not exist, it will be added to the filter form map.

  If the reset option is set to false, the offset will not be reset to 0.

  ## Examples
      iex>  set_filter_form(%Pagify.Meta{}, %{"field" => "name", "operator" => "eq", "value" => "Post 2"})
      %Pagify.Meta{pagify: %Pagify{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 2"}}}

      iex> set_filter_form(%Pagify.Meta{pagify: %Pagify{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}}}, %{"field" => "name", "operator" => "eq", "value" => "Post 2"})
      %Pagify.Meta{pagify: %Pagify{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 2"}}}

      iex> set_filter_form(%Pagify.Meta{pagify: %Pagify{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}}}, %{"negated" => false, "operator" => "and"})
      %Pagify.Meta{pagify: %Pagify{filter_form: nil}}
  """
  @spec set_filter_form(Meta.t(), map(), Keyword.t()) :: Meta.t()
  def set_filter_form(meta, filter_form, opts \\ [])

  def set_filter_form(%Meta{pagify: pagify} = meta, filter_form, opts)
      when filter_form == %{"negated" => false, "operator" => "and"} do
    pagify = maybe_reset_offset(%{pagify | filter_form: nil}, opts)
    %{meta | pagify: pagify}
  end

  def set_filter_form(%Meta{pagify: pagify} = meta, filter_form, opts) do
    pagify = maybe_reset_offset(%{pagify | filter_form: filter_form}, opts)
    %{meta | pagify: pagify}
  end

  defp maybe_reset_offset(%Pagify{} = pagify, opts) do
    reset_on_filter = get_option(:reset_on_filter?, opts, true)

    if reset_on_filter do
      %{pagify | offset: nil}
    else
      pagify
    end
  end

  @doc """
  Helper function to extract all active filter form fields from a Pagify.Meta struct.
  """
  @spec active_filter_form_fields(Meta.t()) :: list()
  def active_filter_form_fields(meta)

  def active_filter_form_fields(%Meta{pagify: %Pagify{filter_form: nil}}), do: []

  def active_filter_form_fields(%Meta{pagify: %Pagify{filter_form: filter_form}}) do
    extract_filter_form_fields(filter_form)
  end

  @doc """
  Helper function to extract all filter form fields from a AshPhoenix.FilterForm parameter.
  """
  @spec extract_filter_form_fields(map() | nil) :: list()
  def extract_filter_form_fields(nil), do: []

  def extract_filter_form_fields(data) do
    data
    |> Map.get("components")
    |> do_extract_filter_form_fields([])
    |> Enum.uniq()
  end

  defp do_extract_filter_form_fields(nil, acc), do: acc

  defp do_extract_filter_form_fields(components, acc) do
    Enum.reduce(components, acc, fn {_key, value}, acc ->
      acc =
        case value do
          %{"operator" => "is_nil", "field" => field} -> [field | acc]
          %{"value" => nil} -> acc
          %{"value" => ""} -> acc
          %{"value" => []} -> acc
          %{"field" => field} -> [field | acc]
          _ -> acc
        end

      case Map.get(value, "components") do
        nil -> acc
        nested_form_parameter -> do_extract_filter_form_fields(nested_form_parameter, acc)
      end
    end)
  end

  @doc """
  Merges the given filters with the filters of a Pagify struct.

  If the filter already exists, it will be replaced with the new value. If the
  filter does not exist, it will be added to the filters map.

  In order to merge the filters, the filters are first prepared by calling `prepare_filters/1`.
  This function will ensure that the filters are in the correct format for merging
  (e.g. keys are strings).

  If the filters are in the correct format, the filters are merged using `Misc.deep_merge/2`.
  After merging, the filters are cleaned up by removing empty lists.

  ## Examples

      iex> merge_filters(%Pagify{filters: %{name: "foo"}}, %{name: "bar"})
      %Pagify{filters: %{"and" => [%{"name" => "bar"}]}}

      iex> merge_filters(%Pagify{filters: %{name: "foo"}}, %{age: 10})
      %Pagify{filters: %{"and" => [%{"name" => "foo"}, %{"age" => 10}]}}

      iex> merge_filters(%Pagify{filters: %{"or" => [%{name: "foo"}]}}, %{age: 10})
      %Pagify{filters: %{"or" => [%{"name" => "foo"}], "and" => [%{"age" => 10}]}}

      iex> merge_filters(%Pagify{filters: %{"or" => [%{name: "foo"}]}}, %{"or" => [%{age: 10}]})
      %Pagify{filters: %{"or" => [%{"name" => "foo"}, %{"age" => 10}]}}
  """
  @spec merge_filters(Pagify.t(), map() | true) :: Pagify.t()
  def merge_filters(pagify, nil), do: pagify
  def merge_filters(pagify, true), do: pagify

  def merge_filters(%Pagify{} = pagify, filters) do
    source = prepare_filters(pagify.filters || %{})
    target = prepare_filters(filters || %{})

    merged =
      source
      |> Misc.deep_merge(target)
      |> Enum.reject(fn {_, value} -> value == [] end)
      |> Map.new()

    %{pagify | filters: merged}
  end

  defp prepare_filters(%{} = filters) do
    keys = Map.keys(filters)

    if length(keys) > 1 do
      filters
    else
      if keys == [] or Enum.member?(~w(and or), Enum.at(keys, 0)) == false do
        %{"and" => [Misc.stringify_keys(filters)]}
      else
        Misc.stringify_keys(filters)
      end
    end
  end

  defp prepare_filters(filters), do: Misc.stringify_keys(filters)

  @doc """
  Transforms the `filter_form` parameter of a `t:Pagify.t/0` into a filter map.

  Used by `Pagify.filter_form/2`. See `AshPhoenix.FilterForm` for more information.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> pagify = %Pagify{filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}}
      iex> filter_form_to_filter_map(Post, pagify.filter_form)
      %{"and" => [%{"name" => %{"eq" => "Post 1"}}]}
  """
  @spec filter_form_to_filter_map(Ash.Resource.t(), map() | nil) :: map()
  def filter_form_to_filter_map(_resource, nil), do: %{}

  def filter_form_to_filter_map(resource, filter_form) do
    resource
    |> FilterForm.new(params: filter_form)
    |> FilterForm.to_filter_map()
    |> elem(1)
  end

  @doc """
  Takes the Pagify.scopes and Pagify.form_filtetr and compiles them into a
  map of filters. The filters are merged with the base filters of the Pagify struct.

  At this stage we assume that the filters, filter_form, and scopes have been validated
  and are valid.

  > #### Full-text search {: .info}
  > Per default we do store the full-text search term in the compiled filters
  map. If you do not need to include the full-text search term in the compiled filters
  map, you can set the `include_full_text_search?` option to `false`.
  The full-text search term is stored under the key `"__full_text_search"` in the
  resulting filters map. This can be handy if you want to store the current filter
  state including the full-text search term and retrieve it later. See
  `Pagify.query_for_filters_map/2` for an example.

  Precedence:
  - scopes (will overwrite filter_form and filters)
  - filter_form (will overwrite filters)
  - filters

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> query_to_filters_map(Post, %Pagify{scopes: [{:role, :admin}]})
      %Pagify{filters: %{"and" => [%{"author" => "John"}]}, scopes: [role: :admin]}

      iex> query_to_filters_map(Post, %Pagify{filters: %{name: "foo"}})
      %Pagify{filters: %{"and" => [%{"name" => "foo"}]}}

      iex> query_to_filters_map(
      ...>   Post,
      ...>   %Pagify{
      ...>     filters: %{author: "Author 1"},
      ...>     filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
      ...>     scopes: [{:role, :admin}]
      ...>   }
      ...> )
      %Pagify{
        scopes: [role: :admin],
        filters: %{"and" => [%{"author" => "John"}, %{"name" => %{"eq" => "Post 1"}}]},
        filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}
      }

      # Or with a full-text search term

      iex> query_to_filters_map(
      ...>   Post,
      ...>   %Pagify{
      ...>     search: "search term",
      ...>     filters: %{author: "Author 1"},
      ...>     filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
      ...>     scopes: [{:role, :admin}]
      ...>   }
      ...> )
      %Pagify{
        scopes: [role: :admin],
        filters: %{
          "and" => [
            %{"author" => "John"},
            %{"name" => %{"eq" => "Post 1"}}
          ],
          "__full_text_search" => %{
            "search" => "search term"
          }
        },
        filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
        search: "search term"
      }
  """
  @spec query_to_filters_map(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) ::
          Pagify.t()
  def query_to_filters_map(query_or_resource, pagify, opts \\ [])

  def query_to_filters_map(%Ash.Query{resource: resource}, %Pagify{} = pagify, opts) do
    filter_form = filter_form_to_filter_map(resource, pagify.filter_form)
    scopes_filters = load_scopes_filters(resource, pagify.scopes, opts)

    pagify
    |> merge_filters(filter_form)
    |> merge_filters(scopes_filters)
    |> maybe_store_full_text_search(resource, opts)
  end

  def query_to_filters_map(r, %Pagify{} = pagify, opts) when is_atom(r) and r != nil do
    query_to_filters_map(Ash.Query.new(r), pagify, opts)
  end

  defp load_scopes_filters(_resource, nil, _opts), do: %{}

  defp load_scopes_filters(resource, scopes, opts) do
    opts = Misc.maybe_put_compiled_pagify_scopes(resource, opts)
    compiled_scopes = Keyword.get(opts, :__compiled_pagify_scopes)

    Enum.reduce(scopes, %{}, fn {group, name}, acc ->
      get_scope_filter(acc, compiled_scopes, group, name)
    end)
  end

  defp get_scope_filter(filters, compiled_scopes, group, name) do
    group_scopes = get_group_scopes(compiled_scopes, group)
    scope = find_scope(group_scopes, group, name)

    if scope.filter != nil do
      Map.merge(filters, scope.filter)
    else
      filters
    end
  end

  defp maybe_store_full_text_search(%Pagify{search: nil} = pagify, _resource, _opts), do: pagify
  defp maybe_store_full_text_search(%Pagify{search: ""} = pagify, _resource, _opts), do: pagify

  defp maybe_store_full_text_search(%Pagify{search: search} = pagify, resource, opts) do
    if search != nil and Keyword.get(opts, :include_full_text_search?, true) do
      store_full_text_search(pagify, resource, opts)
    else
      pagify
    end
  end

  defp store_full_text_search(%Pagify{search: search} = pagify, resource, opts) do
    pagify
    |> Validation.validate_search(Keyword.put_new(opts, :for, resource))
    |> maybe_raise_on_invalid_search(search, opts)
  end

  defp maybe_raise_on_invalid_search(pagify, search, opts) do
    if Map.get(pagify, :errors) == nil do
      user_provided_full_text_search_opts =
        opts
        |> Keyword.get(:full_text_search, [])
        |> Keyword.put(:search, search)
        |> maybe_put_tsvector(get_in(opts, [:full_text_search, :tsvector]))
        |> Enum.filter(fn {key, _} -> key in Pagify.Tsearch.option_keys() end)
        |> Map.new()
        |> Misc.stringify_keys(keys: Pagify.Tsearch.option_keys(), depth: 1)

      %{
        pagify
        | filters:
            Map.put(
              pagify.filters || %{},
              "__full_text_search",
              user_provided_full_text_search_opts
            )
      }
    else
      if Keyword.get(opts, :raise_on_invalid_search?, true) do
        pagify
        |> Map.get(:errors, [])
        |> Keyword.get(:search, [])
        |> hd()
        |> raise()
      else
        pagify
      end
    end
  end

  defp maybe_put_tsvector(opts, nil), do: opts

  defp maybe_put_tsvector(opts, tsvector) when is_binary(tsvector), do: Keyword.put(opts, :tsvector, tsvector)

  defp maybe_put_tsvector(opts, tsvector) when is_atom(tsvector),
    do: Keyword.put(opts, :tsvector, Atom.to_string(tsvector))

  defp maybe_put_tsvector(opts, _), do: opts

  @doc """
  Creates an `Ash.Query` from a filter map. Ideally, the filter map was previously
  compiled with `Pagify.query_to_filters_map/2`.

  Optionally, you can pass the `include_full_text_search?: false` option to disable
  the full-text search term inclusion in the query.

  If the full-text search term is included in the compiled filters map, it will be
  removed from the filters map before the query is created. Further, the full-text
  search is validated before beeing applied to the query. If the full-text search
  is invalid and the `raise_on_invalid_search?` option is not set to `false`, the
  function will raise an error.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> filters_map = %{"and" => [%{"name" => "foo"}]}
      iex> query_for_filters_map(Post, filters_map)
      #Ash.Query<resource: Pagify.Factory.Post, filter: #Ash.Filter<name == "foo">>
  """
  @spec query_for_filters_map(Ash.Query.t() | Ash.Resource.t(), map(), Keyword.t()) ::
          Ash.Query.t()
  def query_for_filters_map(query_or_resource, filters_map, opts \\ [])

  def query_for_filters_map(query_or_resource, %{} = filters_map, opts) do
    {filters_map, full_text_search} = extract_full_text_search(filters_map)

    query_or_resource
    |> Ash.Query.filter_input(filters_map)
    |> maybe_apply_full_text_search(full_text_search, opts)
  end

  @doc """
  Extracts the full-text search term from the filters map and returns a tuple of the filters map
  without the full-text search term and the full-text search term.

  The full-text search term is stored under the key `"__full_text_search"` in the
  filters map (on in the `and` or `or` base of the filters_map). If the full-text
  search term is not found, the function will return the filters map as is.
  """
  @spec extract_full_text_search(map()) :: {map(), map() | nil}
  def extract_full_text_search(%{"__full_text_search" => full_text_search} = filters_map) do
    {Map.delete(filters_map, "__full_text_search"), full_text_search}
  end

  def extract_full_text_search(%{"and" => filters} = filters_map) do
    split_and_combine(filters_map, filters, "and")
  end

  def extract_full_text_search(%{"or" => filters} = filters_map) do
    split_and_combine(filters_map, filters, "or")
  end

  def extract_full_text_search(filters_map), do: {filters_map, nil}

  defp split_and_combine(filters_map, combinator_filters, combinator) do
    {full_text_search, combinator_filters} =
      Enum.split_with(combinator_filters, &Map.has_key?(&1, "__full_text_search"))

    filters_map =
      cond do
        combinator_filters == [] && full_text_search == [] -> filters_map
        combinator_filters == [] -> Map.delete(filters_map, combinator)
        true -> Map.put(filters_map, combinator, combinator_filters)
      end

    full_text_search =
      if full_text_search == [] do
        nil
      else
        full_text_search
        |> hd()
        |> Map.get("__full_text_search", nil)
      end

    {filters_map, full_text_search}
  end

  @spec maybe_apply_full_text_search(Ash.Query.t(), map(), Keyword.t()) :: Ash.Query.t()
  defp maybe_apply_full_text_search(%Ash.Query{} = query, nil, _opts), do: query
  defp maybe_apply_full_text_search(query, %{"search" => nil}, _opts), do: query
  defp maybe_apply_full_text_search(query, %{"search" => ""}, _opts), do: query

  defp maybe_apply_full_text_search(%Ash.Query{} = query, full_text_search, opts) do
    if Keyword.get(opts, :include_full_text_search?, true) do
      apply_full_text_search(query, full_text_search, opts)
    else
      query
    end
  end

  @spec apply_full_text_search(Ash.Query.t(), map(), Keyword.t()) :: Ash.Query.t()
  defp apply_full_text_search(%Ash.Query{resource: r} = query, %{"search" => search} = full_text_search, opts) do
    pagify = %Pagify{search: search}

    full_text_search =
      full_text_search
      |> Map.delete("search")
      |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
      |> Enum.filter(fn {key, _} -> key in Pagify.Tsearch.option_keys() end)

    opts =
      opts
      |> Keyword.put(:full_text_search, full_text_search)
      |> Keyword.put_new(:for, r)

    pagify
    |> Validation.validate_search(opts)
    |> maybe_raise_on_invalid_search_apply(query, opts)
  end

  defp maybe_raise_on_invalid_search_apply(pagify, query, opts) do
    if Map.get(pagify, :errors) == nil do
      search(query, pagify, opts)
    else
      if Keyword.get(opts, :raise_on_invalid_search?, true) do
        pagify
        |> Map.get(:errors, [])
        |> Keyword.get(:search, [])
        |> hd()
        |> raise()
      else
        query
      end
    end
  end

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
    raise Pagify.Error.Query.InvalidDirectionsError, directions: directions
  end

  defp new_order_direction(_, _, nil), do: :asc
  defp new_order_direction(_, _, {asc, _desc}) when is_direction(asc), do: asc

  defp new_order_direction(_, _, directions) do
    raise Pagify.Error.Query.InvalidDirectionsError, directions: directions
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

  For the `:pagify_scopes` option, the function will deep merge the options
  in reverse order (keyword overrides resource, resource overrides global, etc.)

  ## Examples for `:pagify_scopes`

    iex> alias Pagify.Factory.Post
    iex> opts = [
    ...>   pagify_scopes: %{
    ...>     role: [
    ...>       %{name: :user, filter: %{name: "changed"}},
    ...>       %{name: :other, filter: %{name: "other"}}
    ...>     ],
    ...>     status: [
    ...>       %{name: :all, filter: nil, default?: true},
    ...>       %{name: :active, filter: %{age: %{lt: 10}}},
    ...>       %{name: :inactive, filter: %{age: %{gte: 10}}}
    ...>     ]
    ...>   },
    ...>   for: Post
    ...> ]
    iex> get_option(:pagify_scopes, opts, %{
    ...>   role: [
    ...>     %{name: :default, filter: %{author: "Default"}}
    ...>   ]
    ...> })
    %{
      role: [
        %{name: :admin, filter: %{author: "John"}},
        %{name: :user, filter: %{name: "changed"}},
        %{name: :other, filter: %{name: "other"}},
        %{name: :default, filter: %{author: "Default"}}
      ],
      status: [
        %{name: :inactive, filter: %{age: %{gte: 10}}},
        %{name: :all, filter: nil, default?: true},
        %{name: :active, filter: %{age: %{lt: 10}}}
      ]
    }
  """
  @spec get_option(atom(), Keyword.t(), any()) :: any()
  def get_option(key, opts \\ [], default \\ nil)

  def get_option(:pagify_scopes, opts, default) do
    opts_scopes = Keyword.get(opts, :pagify_scopes, %{})
    resource_scopes = resource_option(opts[:for], :pagify_scopes) || %{}
    global_scopes = global_option(:pagify_scopes) || %{}
    default_scopes = Keyword.get(@default_opts, :pagify_scopes, %{})
    default = default || %{}

    default
    |> merge_scopes(default_scopes)
    |> merge_scopes(global_scopes)
    |> merge_scopes(resource_scopes)
    |> merge_scopes(opts_scopes)
  end

  def get_option(key, opts, default) do
    with nil <- opts[key],
         nil <- resource_option(opts[:for], key),
         nil <- global_option(key) do
      Keyword.get(@default_opts, key, default)
    end
  end

  defp merge_scopes(nil, default), do: default

  defp merge_scopes(opts, default) do
    Map.merge(default, opts, fn _key, default_val, opts_val ->
      merge_scope_lists(default_val, opts_val)
    end)
  end

  defp merge_scope_lists(default_list, opts_list) do
    default_map = Map.new(default_list, &{&1[:name], &1})
    opts_map = Map.new(opts_list, &{&1[:name], &1})

    merged_map =
      Map.merge(default_map, opts_map, fn _key, default_item, opts_item ->
        Map.merge(opts_item, default_item)
      end)

    merged_map |> Map.values() |> Enum.reverse()
  end

  defp resource_option(resource, key) when is_atom(resource) and resource != nil and key in @resource_options do
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
