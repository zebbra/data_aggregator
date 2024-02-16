defmodule DataAggregatorWeb.Components.DataTable do
  @moduledoc """
  This component is used to render a table of data.
  """

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
    page = page(params)
    Keyword.put(opts, :page, page)
  end

  def page(params) do
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

  @spec filter_by(Ash.Query.t(), map()) :: Ash.Query.t()
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
