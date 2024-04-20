defmodule Pagify do
  @moduledoc """
  Pagify is a helper library for filtering, ordering and pagination with `Ash`.

  ## Usage

  The simplest way of using this library is just to use
  `Pagify.validate_and_run/3` and `Pagify.validate_and_run!/3`. Both functions
  take an `t:Ash.Query.t/0` or `t:Ash.Resource.t/0` and a parameter map, validate
  the parameters, run the query and return the query results and the meta information.

      iex> alias Pagify.Factory.Post
      iex> params = %{order_by: ["name", "author"], offset: 0, limit: 2}
      iex> {:ok, {results, meta}} =
      ...>   Pagify.validate_and_run(
      ...>     Post,
      ...>     params
      ...>   )
      iex> Enum.map(results, & &1.name)
      ["Post 1", "Post 2"]
      iex> meta.total_count
      3
      iex> meta.total_pages
      2
      iex> meta.has_next_page?
      true

  Under the hood, these functions just call `Pagify.validate/2` and `Pagify.run/3`,
  which in turn calls `Pagify.all/3` and `Pagify.meta/3`. If you need finer control
  about if and when to execute each step, you can call those functions directly.

  See `Pagify.Meta` for descriptions of the meta fields.

  ## Resource configuration

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

  ## Pagination

  We use queries using `OFFSET` and `LIMIT`, with offset-based pagination
  parameters:

      %{offset: 100, limit: 20}

  ## Filters

  Filters can be passed as a list of maps or plain maps.

      iex> params = %{filters: %{name: "Post 1"}}
      iex> {:ok, {results, meta}} = Pagify.validate_and_run(Post, params)
      iex> meta.total_count
      1
      iex> [post] = results
      iex> post.name
      "Post 1"

  See `Ash.Query.filter_input/2` for a list of all available filter operators.
  """
  alias Pagify.Meta
  alias Pagify.Validation

  require Logger

  @default_limit 25
  def default_limit, do: @default_limit

  @default_max_limit 100
  def default_max_limit, do: @default_max_limit

  defstruct limit: nil, offset: nil, filters: nil, order_by: nil

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
          order_by:
            String.t()
            | [atom() | String.t() | {atom(), Ash.Sort.sort_order()} | [String.t()]]
            | nil
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

  def parse(r, %Pagify{} = pagify, opts) when is_atom(r) do
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

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine.
  """
  @spec all(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) :: Ash.Page.Offset.t()
  def all(query_or_resource, pagify, opts \\ [])

  def all(%Ash.Query{resource: r} = q, %Pagify{} = pagify, opts) do
    opts = parse(q, pagify, opts)
    r.read!(opts)
  end

  def all(r, %Pagify{} = pagify, opts) when is_atom(r) do
    all(Ash.Query.to_query(r), pagify, opts)
  end

  @doc """
  Applies the given `t:Pagify.t/0` to the given `t:Ash.Query.t/0` or `t:Ash.Resource.t/0`,
  retrieves the data and the `t:Pagify.Meta.t/0` data.

  This function does _not_ validate or apply default parameters to the given
  Pagify struct. Be sure to validate any user-generated parameters with
  `validate/2` or `validate!/2` before passing them to this function. Doing so
  will automatically parse user provided input into the correct format for the
  query engine. Or you can use `Pagify.validate_and_run/3` or
  `Pagify.validate_and_run!/3` instead of this function.

  ## Examples

      iex> alias Pagify.Factory.Post
      iex> opts = [page: [count: false]]
      iex> pagify = Pagify.validate!(Post, %{filters: %{name: "inexistent"}}, opts)
      iex> {data, meta} = Pagify.run(Post, pagify, opts)
      iex> data == []
      true
      iex> match?(%Pagify.Meta{}, meta)
      true

  See the documentation for `Pagify.validate_and_run/3` for supported options.
  """
  @spec run(Ash.Query.t() | Ash.Resource.t(), Pagify.t(), Keyword.t()) ::
          {[Ash.Resource.record()], Meta.t()}
  def run(query_or_resource, pagify, opts \\ [])

  def run(%Ash.Query{} = q, %Pagify{} = pagify, opts) do
    page = all(q, pagify, opts)
    meta = meta(page, pagify, opts)
    {page.results, meta}
  end

  def run(r, %Pagify{} = pagify, opts) when is_atom(r) do
    run(Ash.Query.to_query(r), pagify, opts)
  end

  @doc """
  Validates the given pagify parameters and retrieves the data and meta data on
  success.

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


  ## Options

  The keyword list `opts` is used to pass additional options to the query engine.
  It shoud conform to the list of valid options at `c:Ash.Api.read/2`. Furthermore
  the following options are supported:

  - `:default_limit` - The default number of records to return. Defaults to 25.
    Can be overridden by the resource's `default_limit` function.
  - `:max_limit` - The maximum number of records that can be returned. Defaults
    to 100.
  - `:replace_invalid_params?` - If set to `true`, invalid parameters will be
    replaced with the default value. If set to `false`, invalid parameters
    will result in an error. Defaults to `true`.
  """
  @spec validate_and_run(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t()) ::
          {:ok, {[Ash.Resource.record()], Meta.t()}} | {:error, Meta.t()}
  def validate_and_run(query_or_resource, map_or_pagify, opts \\ []) do
    with {:ok, pagify} <- validate(query_or_resource, map_or_pagify, opts) do
      {:ok, run(query_or_resource, pagify, opts)}
    end
  end

  @doc """
  Same as `Pagify.validate_and_run/3`, but raises on error.
  """
  @spec validate_and_run!(Ash.Query.t() | Ash.Resource.t(), map() | Pagify.t(), Keyword.t()) ::
          {[Ash.Resource.record()], Meta.t()}
  def validate_and_run!(query_or_resource, map_or_pagify, opts \\ []) do
    pagify = validate!(query_or_resource, map_or_pagify, opts)
    run(query_or_resource, pagify, opts)
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

    current_order_by = get_current_order_by(page)

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
      total_count: total_count,
      total_pages: total_pages
    }
  end

  defp get_previous(offset, limit) do
    has_previous? = offset > 0
    previous_offset = if has_previous?, do: max(0, offset - limit)

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

  defp get_current_order_by(%Ash.Page.Offset{rerun: {%Ash.Query{} = q, _}}) do
    case q do
      %Ash.Query{sort: sort} -> concat_sort(sort)
      _ -> nil
    end
  end

  defp concat_sort(list, acc \\ [])
  defp concat_sort([], []), do: nil
  defp concat_sort([], acc), do: Enum.reverse(acc)

  defp concat_sort([field | rest], acc) do
    case field do
      {field, order} ->
        concat_sort(rest, ["#{order_to_prefix(order)}#{Atom.to_string(field)}" | acc])

      field ->
        concat_sort(rest, [Atom.to_string(field) | acc])
    end
  end

  defp order_to_prefix(:asc_nils_last), do: "++"
  defp order_to_prefix(:desc), do: "-"
  defp order_to_prefix(:desc_nils_last), do: "--"
  defp order_to_prefix(_), do: ""

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

  def paginate(r, pagify, opts) when is_atom(r) do
    paginate(Ash.Query.to_query(r), pagify, opts)
  end

  @spec put_default_limit(Ash.Query.t(), Pagify.t()) :: Pagify.t()
  defp put_default_limit(q, pagify)

  defp put_default_limit(%Ash.Query{resource: r}, %Pagify{limit: nil} = pagify) when is_atom(r) do
    if Keyword.has_key?(r.__info__(:functions), :default_limit) do
      %{pagify | limit: r.default_limit()}
    else
      %{pagify | limit: @default_limit}
    end
  end

  defp put_default_limit(_, %Pagify{limit: nil} = pagify) do
    %{pagify | limit: @default_limit}
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
    |> Keyword.put(:limit, @default_limit)
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
    |> Keyword.put(:limit, @default_limit)
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
end
