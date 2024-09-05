defmodule DataAggregator.Helpers do
  @moduledoc """
  Generic helpers for the DataAggregator application.
  """

  import Ash.Expr

  alias DataAggregator.Accounts.User

  require Ash.Query

  @doc """
  Returns a list of distinct values for a given field in a resource.
  """
  @spec distinct(Ash.Resource.t() | Ash.Query.t(), atom()) :: [String.t()]
  def distinct(resource_or_query, field) do
    resource_or_query
    |> Ash.Query.filter(^ref(field) != "")
    |> Ash.Query.distinct(field)
    |> Ash.Query.distinct_sort(field)
    |> Ash.Query.select(field)
    |> Ash.read!()
    |> Enum.map(&Map.get(&1, field))
  end

  @doc """
  Generate a map from a user which can be passed as an actor to a worker.
  """
  @spec actor_map(User.t()) :: map()
  def actor_map(actor) when is_struct(actor) do
    actor
    |> Map.from_struct()
    |> Map.take([:id, :institution_id, :roles])
  end

  def actor_map(actor), do: actor
end
