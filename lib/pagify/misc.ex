defmodule Pagify.Misc do
  @moduledoc """
  Miscellaneous functions for Pagify.
  """

  @doc """
  Convert map string keys to :atom keys. This is useful when
  you have a map that was created from JSON or other external
  source and you want to convert the keys to atoms.

  You can specify a list of keys to convert or a depth to which
  to convert keys. If you specify a depth of 1, only the top
  level keys will be converted. If you specify a depth of 2, the
  top level keys and the keys of any maps in the top level will
  be converted. And so on.

  If you set the existing? option to true, the function will use
  the `String.to_existing_atom/1` function to convert the keys.

  List of options:

  - `keys`: A list of keys to convert. If a key is not in the list,
    it will not be converted. Default is an empty list and all keys
    will be converted.
  - `depth`: The depth to which to convert keys. Default is nil and
    all keys will be converted.
  - `existing?`: If true, the function will use `String.to_existing_atom/1`
    to convert the keys. Default is false.

  ## Example

      iex> Pagify.Misc.atomize_keys(%{"a" => 1, "b" => 2})
      %{a: 1, b: 2}

      iex> Pagify.Misc.atomize_keys(%{"a" => 1, "b" => %{"c" => 3}})
      %{a: 1, b: %{c: 3}}

      iex> Pagify.Misc.atomize_keys(%{"a" => 1, "b" => %{"c" => 3}}, keys: ["b"])
      %{"a" => 1, b: %{"c" => 3}}

      iex> Pagify.Misc.atomize_keys(%{"a" => 1, "b" => %{"c" => 3}}, keys: ["b", "c"])
      %{"a" => 1, b: %{c: 3}}

      iex> Pagify.Misc.atomize_keys(%{"a" => 1, "b" => %{"c" => 3}}, keys: ["b", "d"], depth: 1)
      %{"a" => 1, b: %{"c" => 3}}

      iex> Pagify.Misc.atomize_keys(%{"a" => 1, "b" => %{"c" => 3}}, keys: ["b", "c"], depth: 2)
      %{"a" => 1, b: %{c: 3}}
  """
  @spec atomize_keys(map() | struct(), Keyword.t()) :: map() | struct()
  def atomize_keys(map_or_struct, opts \\ [])
  def atomize_keys(nil, _), do: nil
  def atomize_keys(%{__struct__: _} = struct, _), do: struct

  def atomize_keys(%{} = map, opts),
    do: walk_map(map, Keyword.get(opts, :keys, []), Keyword.get(opts, :depth, nil), Keyword.get(opts, :existing?, false))

  def atomize_keys(not_a_map, _), do: not_a_map

  defp walk_map(map, keys, depth, existing?, current_depth \\ 1)

  defp walk_map(%{} = map, keys, depth, existing?, current_depth) do
    Map.new(map, fn {k, v} ->
      if is_nil(depth) == false and current_depth >= depth do
        {atomize_key(k, keys, existing?), v}
      else
        {atomize_key(k, keys, existing?), walk_map(v, keys, depth, existing?, current_depth + 1)}
      end
    end)
  end

  defp walk_map([head | rest], keys, depth, existing?, current_depth) do
    [
      walk_map(head, keys, depth, existing?, current_depth)
      | walk_map(rest, keys, depth, existing?, current_depth)
    ]
  end

  defp walk_map(not_a_map, _, _, _, _), do: not_a_map

  defp atomize_key(key, [], existing?) when is_binary(key) do
    if existing? do
      String.to_existing_atom(key)
    else
      String.to_atom(key)
    end
  end

  defp atomize_key(key, keys, existing?) when is_binary(key) and is_list(keys) do
    if Enum.member?(keys, key) do
      atomize_key(key, [], existing?)
    else
      key
    end
  end

  defp atomize_key(key, _, _), do: key

  @doc """
  Returns a list of unique keywords from a list of keywords while
  preserving the order of the first occurrence of each keyword.

  ## Example

      iex> Pagify.Misc.unique_keywords([:a, :b, :a, :c, :b])
      [:a, :b, :c]

      iex> Pagify.Misc.unique_keywords([a: 1, b: 2, a: 3, c: 4, b: 5])
      [a: 1, b: 2, c: 4]
  """
  def unique_keywords(keyword_list) when is_list(keyword_list) do
    unique_keywords(keyword_list, %{}, [])
  end

  defp unique_keywords([], _seen, result) do
    Enum.reverse(result)
  end

  defp unique_keywords([{key, value} | rest], seen, result) do
    case Map.get(seen, key) do
      nil ->
        unique_keywords(rest, Map.put(seen, key, value), [{key, value} | result])

      _ ->
        unique_keywords(rest, seen, result)
    end
  end

  defp unique_keywords([keyword | rest], seen, result) do
    case Map.get(seen, keyword) do
      nil ->
        unique_keywords(rest, Map.put(seen, keyword, true), [keyword | result])

      _ ->
        unique_keywords(rest, seen, result)
    end
  end
end
