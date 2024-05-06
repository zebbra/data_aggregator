defmodule Pagify.Validation do
  @moduledoc """
  Utilities for validating and transforming filtering, ordering and pagination parameters.
  """

  alias Ash.Error.Query.InvalidLimit
  alias Ash.Error.Query.InvalidOffset
  alias Pagify.Error.Query.InvalidOrderByParameter

  @spec validate_params(Ash.Query.t() | Ash.Resource.t(), map(), Keyword.t()) ::
          {:ok, Pagify.t()} | {:error, any(), map()}
  def validate_params(query_or_resource, params, opts \\ [])

  def validate_params(%Ash.Query{resource: r}, params, opts) do
    validate_params(r, params, opts)
  end

  def validate_params(resource, %{} = params, opts) do
    replace_invalid_params? = Keyword.get(opts, :replace_invalid_params?, false)

    maybe_valid_params =
      params
      |> Map.put(:errors, [])
      |> validate_filters(resource, replace_invalid_params?)
      |> validate_order_by(resource, replace_invalid_params?)
      |> validate_pagination(resource, replace_invalid_params?, opts)

    case maybe_valid_params do
      %{errors: []} -> {:ok, struct(%Pagify{}, maybe_valid_params)}
      %{errors: errors} -> {:error, errors, Map.delete(maybe_valid_params, :errors)}
    end
  end

  # Filter validation

  @doc """
  Validates the filters in the given parameters.

  If `replace_invalid_params?` is `true`, invalid
  filters are removed and an error is added to the `:errors` key in the returned map. If
  `replace_invalid_params?` is `false`, invalid filters are not removed and an error is added to
  the `:errors` key in the returned map. Only the first error is added to the `:errors` key.

  If the `:filters` key is `nil`, it is returned as is.

  ## Examples

      iex> Pagify.Validation.validate_filters(%{}, Post)
      %{}

      iex> Pagify.Validation.validate_filters(%{filters: nil}, Post)
      %{filters: nil}

      iex> %{filters: filters} = Pagify.Validation.validate_filters(%{filters: [%{name: "Post 1"}]}, Post)
      iex> filters
      #Ash.Filter<name == "Post 1">

      iex> %{filters: filters, errors: errors} = Pagify.Validation.validate_filters(%{filters: 1}, Post, true)
      iex> filters
      nil
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        filters: [
          %Ash.Error.Query.InvalidFilterValue{value: 1}
        ]
      ]

      iex> %{filters: filters, errors: errors} = Pagify.Validation.validate_filters(%{filters: 1}, Post)
      iex> filters
      1
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        filters: [
          %Ash.Error.Query.InvalidFilterValue{value: 1}
        ]
      ]
  """
  @spec validate_filters(map(), Ash.Resource.t(), boolean()) :: map()
  def validate_filters(params, resource, replace_invalid_params? \\ false)
  def validate_filters(%{filters: nil} = params, _, _), do: params

  def validate_filters(%{filters: filters} = params, resource, false) when is_map(filters) or is_list(filters) do
    case Ash.Filter.parse_input(resource, filters) do
      {:ok, filters} ->
        Map.put(params, :filters, filters)

      {:error, error} ->
        add_error(params, :filters, error)
    end
  end

  def validate_filters(%{filters: filters} = params, resource, true) when is_map(filters) or is_list(filters) do
    case Ash.Filter.parse_input(resource, filters) do
      {:ok, filters} ->
        Map.put(params, :filters, filters)

      {:error, _} ->
        replace_invalid_filters(filters, params, resource)
    end
  end

  def validate_filters(%{filters: filters} = params, resource, replace_invalid_params?) do
    case Ash.Filter.parse_input(resource, filters) do
      {:ok, filters} ->
        Map.put(params, :filters, filters)

      {:error, error} ->
        params = add_error(params, :filters, error)

        if replace_invalid_params? do
          Map.put(params, :filters, nil)
        else
          params
        end
    end
  end

  def validate_filters(params, _, _), do: params

  defp replace_invalid_filters(filters, params, resource) do
    case Ash.Filter.parse_input(resource, filters) do
      {:ok, filters} ->
        if Ash.Filter.list_predicates(filters) == [] do
          Map.put(params, :filters, nil)
        else
          Map.put(params, :filters, filters)
        end

      {:error, error} ->
        params = add_error(params, :filters, error)
        filters = remove_key(filters, error.attribute_or_relationship)
        replace_invalid_filters(filters, params, resource)
    end
  end

  defp remove_key(map, key) when is_map(map) do
    if Map.has_key?(map, key) do
      Map.delete(map, key)
    else
      Map.new(
        Enum.map(map, fn {k, v} ->
          {k, remove_key(v, key)}
        end)
      )
    end
  end

  defp remove_key(list, key) when is_list(list) do
    Enum.map(list, fn item -> remove_key(item, key) end)
  end

  defp remove_key(value, _), do: value

  # Order by validation

  @doc """
  Validates the order by in the given parameters.

  If `replace_invalid_params?` is `true`, invalid
  order by values are removed and an error is added to the `:errors` key in the returned map. If
  `replace_invalid_params?` is `false`, invalid order by values are not removed and an error is added
  to the `:errors` key in the returned map. Only the first error is added to the `:errors` key.

  If the `:order_by` key is `nil`, it is returned as is.

  ## Examples

      iex> Pagify.Validation.validate_order_by(%{}, Post)
      %{}

      iex> Pagify.Validation.validate_order_by(%{order_by: nil}, Post)
      %{order_by: nil}

      iex> %{order_by: order_by} = Pagify.Validation.validate_order_by(%{order_by: ["name"]}, Post)
      iex> order_by
      [name: :asc]

      iex> %{order_by: order_by} = Pagify.Validation.validate_order_by(%{order_by: "++name"}, Post)
      iex> order_by
      [name: :asc_nils_first]

      iex> %{order_by: order_by} = Pagify.Validation.validate_order_by(%{order_by: "name,--comments_count"}, Post)
      iex> order_by
      [name: :asc, comments_count: :desc_nils_last]

      iex> %{order_by: order_by, errors: errors} = Pagify.Validation.validate_order_by(%{order_by: "--name,non_existent"}, Post, true)
      iex> order_by
      [name: :desc_nils_last]
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        order_by: [
          %Ash.Error.Query.NoSuchAttribute{name: "non_existent", resource: Post}
        ]
      ]
  """
  @spec validate_order_by(map(), Ash.Resource.t(), boolean()) :: map()
  def validate_order_by(params, resource, replace_invalid_params? \\ false)
  def validate_order_by(%{order_by: nil} = params, _, _), do: params

  def validate_order_by(%{order_by: order_by} = params, resource, replace_invalid_params?) when is_atom(order_by) do
    params = Map.update!(params, :order_by, &Atom.to_string(&1))
    validate_order_by(params, resource, replace_invalid_params?)
  end

  def validate_order_by(%{order_by: order_by} = params, resource, false) when is_list(order_by) do
    case Ash.Sort.parse_input(resource, order_by) do
      {:ok, order_by} ->
        Map.put(params, :order_by, order_by)

      {:error, error} ->
        add_error(params, :order_by, error)
    end
  end

  def validate_order_by(%{order_by: order_by} = params, resource, true) when is_list(order_by) do
    case Ash.Sort.parse_input(resource, order_by) do
      {:ok, order_by} ->
        Map.put(params, :order_by, order_by)

      {:error, _} ->
        replace_invalid_order_by(order_by, params, resource)
    end
  end

  def validate_order_by(%{order_by: order_by} = params, resource, replace_invalid_params?) when is_binary(order_by) do
    validate_order_by(
      %{params | order_by: String.split(order_by, ",")},
      resource,
      replace_invalid_params?
    )
  end

  def validate_order_by(%{order_by: order_by} = params, _, false) when is_map(order_by) do
    add_error(params, :order_by, InvalidOrderByParameter.exception(order_by: order_by))
  end

  def validate_order_by(%{order_by: order_by} = params, _, true) when is_map(order_by) do
    params = add_error(params, :order_by, InvalidOrderByParameter.exception(order_by: order_by))
    Map.put(params, :order_by, nil)
  end

  def validate_order_by(params, _, false) do
    if Map.get(params, :order_by) == nil do
      params
    else
      add_error(params, :order_by, InvalidOrderByParameter.exception(order_by: params[:order_by]))
    end
  end

  def validate_order_by(params, _, true) do
    if Map.get(params, :order_by) == nil do
      params
    else
      params =
        add_error(
          params,
          :order_by,
          InvalidOrderByParameter.exception(order_by: params[:order_by])
        )

      Map.put(params, :order_by, nil)
    end
  end

  defp replace_invalid_order_by(order_by, params, resource) do
    case Ash.Sort.parse_input(resource, order_by) do
      {:ok, order_by} ->
        if order_by == [] do
          Map.put(params, :order_by, nil)
        else
          Map.put(params, :order_by, order_by)
        end

      {:error, error} ->
        params = add_error(params, :order_by, error)
        order_by = List.delete(order_by, error.name)
        replace_invalid_order_by(order_by, params, resource)
    end
  end

  # Pagination validation

  @doc """
  Validates the pagination parameters in the given parameters.

  If `replace_invalid_params?` is `true`,
  invalid pagination parameters are removed / replaced and an error is added to the `:errors` key in
  the returned map. If `replace_invalid_params?` is `false`, invalid pagination parameters are not
  removed and an error is added to the `:errors` key in the returned map.

  If the `:limit` key is `nil`, the default_limit value is applied. The default_limit value is determined by
  the resource's `default_limit` function or the `:default_limit` option provided to this function or
  the `Pagify.default_limit()` value.

  If the `:offset` key is `nil`, it is returned as is.

  ## Examples

      iex> Pagify.Validation.validate_pagination(%{}, Post)
      %{limit: 15, offset: 0}

      iex> Pagify.Validation.validate_pagination(%{limit: nil}, Post)
      %{limit: 15, offset: 0}

      iex> %{limit: limit} = Pagify.Validation.validate_pagination(%{limit: 10}, Post)
      iex> limit
      10

      iex> %{limit: limit, errors: errors} = Pagify.Validation.validate_pagination(%{limit: 0}, Post, true)
      iex> limit
      15
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        limit: [
          %Ash.Error.Query.InvalidLimit{limit: 0}
        ]
      ]

      iex> %{limit: limit} = Pagify.Validation.validate_pagination(%{limit: 100}, Post)
      iex> limit
      100

      iex> %{limit: limit, errors: errors} = Pagify.Validation.validate_pagination(%{limit: -1}, Post, true)
      iex> limit
      15
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        limit: [
          %Ash.Error.Query.InvalidLimit{limit: -1}
        ]
      ]

      iex> %{offset: offset} = Pagify.Validation.validate_pagination(%{offset: 10}, Post)
      iex> offset
      10

      iex> %{offset: offset, errors: errors} = Pagify.Validation.validate_pagination(%{offset: -1}, Post, true)
      iex> offset
      0
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        offset: [
          %Ash.Error.Query.InvalidOffset{offset: -1}
        ]
      ]

      iex> %{offset: offset, errors: errors} = Pagify.Validation.validate_pagination(%{offset: -1}, Post)
      iex> offset
      -1
      iex> Pagify.Error.clear_stacktrace(errors)
      [
        offset: [
          %Ash.Error.Query.InvalidOffset{offset: -1}
        ]
      ]
  """
  @spec validate_pagination(map(), Ash.Resource.t(), boolean(), Keyword.t()) :: map()
  def validate_pagination(params, resource, replace_invalid_params? \\ false, opts \\ []) do
    params
    |> validate_and_maybe_delete(:limit, &validate_limit/2, opts, replace_invalid_params?)
    |> put_default_limit(resource, opts)
    |> validate_and_maybe_delete(:offset, &validate_offset/2, opts, replace_invalid_params?)
    |> put_default_offset()
  end

  defp validate_and_maybe_delete(params, key, validate_func, opts, true) do
    validated_params = validate_func.(params, opts)

    case validated_params do
      {:ok, validated_params} -> validated_params
      {:error, validated_params} -> Map.put(validated_params, key, nil)
    end
  end

  defp validate_and_maybe_delete(params, _key, validate_func, opts, _) do
    {_, validated_params} = validate_func.(params, opts)
    validated_params
  end

  defp validate_limit(%{limit: nil} = params, _opts), do: {:ok, params}

  defp validate_limit(%{limit: limit} = params, opts) when is_integer(limit) do
    if limit > 0 do
      max_limit = Keyword.get(opts, :max_limit, Pagify.default_max_limit())
      validate_within_max_limit(params, max_limit)
    else
      {:error, add_error(params, :limit, InvalidLimit.exception(limit: limit))}
    end
  end

  defp validate_limit(params, _opts) do
    case Map.get(params, :limit) do
      nil -> {:ok, params}
      limit -> {:error, add_error(params, :limit, InvalidLimit.exception(limit: limit))}
    end
  end

  defp validate_within_max_limit(params, nil) do
    {:ok, params}
  end

  defp validate_within_max_limit(%{limit: limit} = params, max_limit) do
    if limit <= max_limit do
      {:ok, params}
    else
      {:error, add_error(params, :limit, InvalidLimit.exception(limit: limit))}
    end
  end

  defp put_default_limit(%{limit: nil} = params, resource, opts) do
    Map.put(params, :limit, default_limit(resource, opts))
  end

  defp put_default_limit(params, resource, opts) do
    Map.put_new_lazy(params, :limit, fn -> default_limit(resource, opts) end)
  end

  defp default_limit(resource, opts) do
    if Keyword.get(opts, :default_limit) == false do
      nil
    else
      opts = Keyword.put(opts, :for, resource)
      Pagify.get_option(:default_limit, opts)
    end
  end

  defp validate_offset(%{offset: offset} = params, _opts) when is_integer(offset) do
    if offset >= 0 do
      {:ok, params}
    else
      {:error, add_error(params, :offset, InvalidOffset.exception(offset: offset))}
    end
  end

  defp validate_offset(params, _opts), do: {:ok, params}

  defp put_default_offset(%{offset: nil} = params) do
    Map.put(params, :offset, 0)
  end

  defp put_default_offset(params) do
    Map.put_new(params, :offset, 0)
  end

  defp add_error(params, key, ash_error) do
    params = Map.put_new_lazy(params, :errors, fn -> [] end)

    errors =
      params
      |> Map.get(:errors, [])
      |> Keyword.put(key, [ash_error | Keyword.get(params.errors, key, [])])

    Map.put(params, :errors, errors)
  end
end
