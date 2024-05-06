defmodule Pagify.Misc do
  @moduledoc """
  Miscellaneous functions for Pagify.
  """

  @doc """
  Convert map string keys to :atom keys
  """
  def atomize_keys(nil), do: nil

  # Structs don't do enumerable and anyway the keys are already
  # atoms
  def atomize_keys(%{__struct__: _} = struct) do
    struct
  end

  def atomize_keys(%{} = map) do
    Map.new(map, fn {k, v} -> {atomize_key(k), atomize_keys(v)} end)
  end

  # Walk the list and atomize the keys of
  # of any map members
  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end

  defp atomize_key(key) when is_binary(key) do
    String.to_atom(key)
  end

  defp atomize_key(key) do
    key
  end

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
