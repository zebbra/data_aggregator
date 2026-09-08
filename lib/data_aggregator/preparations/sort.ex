defmodule DataAggregator.Preparations.Sort do
  @moduledoc """
  Ash preparation to sort resources using a `sort` action argument.
  """

  use Ash.Resource.Preparation

  require Logger

  @impl true
  def prepare(query, _opts, _context) do
    sort = Ash.Query.get_argument(query, :sort)

    # Filter out empty, nil, or invalid sort values
    cleaned_sort = clean_sort_input(sort)

    if cleaned_sort && cleaned_sort != [] do
      case Ash.Sort.parse_input(query.resource, cleaned_sort) do
        {:ok, sort} ->
          Ash.Query.sort(query, sort, prepend?: true)

        {:error, error} ->
          Logger.warning("Invalid sort: #{inspect(error)}")
          query
      end
    else
      query
    end
  end

  defp clean_sort_input(nil), do: nil
  defp clean_sort_input([]), do: []

  defp clean_sort_input(sort) when is_list(sort) do
    sort
    |> Enum.filter(&valid_sort_item?/1)
    |> case do
      [] -> nil
      filtered -> filtered
    end
  end

  defp clean_sort_input(sort) when is_binary(sort) and sort != "", do: sort
  defp clean_sort_input(sort) when is_atom(sort), do: sort

  defp clean_sort_input({field, direction}) when is_binary(field) and field != "" do
    {field, direction}
  end

  defp clean_sort_input({field, direction}) when is_atom(field) do
    {field, direction}
  end

  defp clean_sort_input(_), do: nil

  defp valid_sort_item?(item) when is_binary(item) and item != "", do: true
  defp valid_sort_item?(item) when is_atom(item), do: true
  defp valid_sort_item?({field, _direction}) when is_binary(field) and field != "", do: true
  defp valid_sort_item?({field, _direction}) when is_atom(field), do: true
  defp valid_sort_item?(_), do: false
end
