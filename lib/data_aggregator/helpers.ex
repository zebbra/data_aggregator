defmodule DataAggregator.Helpers do
  @moduledoc """
  Generic helpers for the DataAggregator application.
  """

  alias DataAggregator.Accounts.User

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
