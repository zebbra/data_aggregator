defmodule DataAggregator.Helpers do
  @moduledoc """
  Generic helpers for the DataAggregator application.
  """

  @doc """
  Returns a list of distinct values for a given field in a resource.
  """
  @spec distinct(Ash.Resource.t(), atom()) :: [String.t()]
  def distinct(resource, field) do
    resource
    |> Ash.Query.distinct(field)
    |> Ash.Query.select(field)
    |> Ash.Query.sort(field)
    |> Ash.read!()
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&(&1 != nil))
  end
end
