defmodule Pagify.Components.Misc do
  @moduledoc false

  @doc """
  Deep merge for keyword lists.

      iex> deep_merge(
      ...>   [aria: [role: "navigation"]],
      ...>   [aria: [label: "pagination"]]
      ...> )
      [aria: [role: "navigation", label: "pagination"]]

      iex> deep_merge(
      ...>   [class: "a"],
      ...>   [class: "b"]
      ...> )
      [class: "b"]
  """
  @spec deep_merge(keyword, keyword) :: keyword
  def deep_merge(a, b) when is_list(a) and is_list(b) do
    Keyword.merge(a, b, &do_deep_merge/3)
  end

  defp do_deep_merge(_key, a, b) when is_list(a) and is_list(b) do
    deep_merge(a, b)
  end

  defp do_deep_merge(_key, _, b), do: b

  @doc """
  Puts a `value` under `key` only if the value is not `nil`, `[]` or `%{}`.

  If a `:default` value is passed, it only puts the value into the list if the
  value does not match the default value.

      iex> maybe_put([], :a, "b")
      [a: "b"]

      iex> maybe_put([], :a, nil)
      []

      iex> maybe_put([], :a, [])
      []

      iex> maybe_put([], :a, %{})
      []

      iex> maybe_put([], :a, "a", "a")
      []

      iex> maybe_put([], :a, "a", "b")
      [a: "a"]
  """
  @spec maybe_put(Keyword.t(), atom(), any(), any()) :: keyword
  def maybe_put(params, key, value, default \\ nil)
  def maybe_put(keywords, _, nil, _), do: keywords
  def maybe_put(keywords, _, [], _), do: keywords
  def maybe_put(keywords, _, map, _) when map == %{}, do: keywords
  def maybe_put(keywords, _, val, val), do: keywords
  def maybe_put(keywords, key, value, _), do: Keyword.put(keywords, key, value)

  @doc """
  Puts the scopes params of a Pagify struct into a keyword list only if they don't
  match the defaults either passed as last argument or loaded on the fly.

  Example:

      iex> maybe_put_scopes([], %Pagify{scopes: %{status: :inactive}}, default_scopes: %{status: :active})
      [scopes: %{status: :inactive}]

      iex> maybe_put_scopes([], %Pagify{scopes: %{status: :active}}, default_scopes: %{status: :active})
      []

      iex> alias Pagify.Factory.Post
      iex> maybe_put_scopes([], %Pagify{scopes: %{status: :active}}, for: Post)
      [scopes: %{status: :active}]
  """
  @spec maybe_put_scopes(Keyword.t(), Pagify.t(), Keyword.t()) :: Keyword.t()
  def maybe_put_scopes(keywords, pagify, opts \\ [])

  def maybe_put_scopes(keywords, pagify, opts) do
    default_scopes = maybe_load_default_scopes(opts)
    scopes = pagify.scopes || %{}

    scopes =
      scopes
      |> Enum.reduce(%{}, fn {group, name}, acc ->
        if default_scope?(group, name, default_scopes) do
          acc
        else
          Map.put(acc, group, name)
        end
      end)
      |> Pagify.Misc.coerce_maybe_empty_map()

    maybe_put(keywords, :scopes, scopes)
  end

  defp maybe_load_default_scopes(opts) do
    if Keyword.has_key?(opts, :default_scopes) do
      Keyword.get(opts, :default_scopes, %{})
    else
      resource = Keyword.get(opts, :for)
      opts = Pagify.Misc.maybe_put_compiled_pagify_scopes(resource, opts)
      Keyword.get(opts, :__compiled_pagify_default_scopes, %{})
    end
  end

  defp default_scope?(_, _, nil), do: false

  defp default_scope?(group, name, default_scopes) do
    Map.get(default_scopes, group) == name
  end

  @doc """
  Returns the global opts derived from a function referenced in the application
  environment.
  """
  @spec get_global_opts(atom) :: keyword
  def get_global_opts(component) when component in [:pagination, :table] do
    case opts_func(component) do
      nil -> []
      {module, func} -> apply(module, func, [])
    end
  end

  defp opts_func(component) do
    :data_aggregator
    |> Application.get_env(:pagify_phoenix, [])
    |> Keyword.get(component, [])
    |> Keyword.get(:opts)
  end

  @doc """
  Remove nil values from a map or struct. Does not work with nested maps.

  ## Example

      iex> Pagify.Components.Misc.remove_nil_values(%{a: 1, b: nil, c: 3})
      %{a: 1, c: 3}

      iex> Pagify.Components.Misc.remove_nil_values(%{a: 1, b: %{c: nil, d: 4}})
      %{a: 1, b: %{c: nil, d: 4}}
  """
  def remove_nil_values(map_or_struct)
  def remove_nil_values(nil), do: nil

  def remove_nil_values(struct) when is_atom(struct) do
    struct
    |> Map.from_struct()
    |> remove_nil_values()
  end

  def remove_nil_values(%{} = map) do
    map
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end
end
