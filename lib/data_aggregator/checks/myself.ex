defmodule DataAggregator.Checks.Myself do
  @moduledoc """
  Check if the actor is the same as the resource being accessed.
  """
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts) do
    "it's the actor"
  end

  @impl true
  def requires_original_data?(_, _), do: false

  @impl true
  def match?(nil, _, _), do: false

  @impl true
  def match?(%{id: actor_id}, context, _opts) do
    user_id = Ash.Changeset.get_data(context.changeset, :id)
    actor_id == user_id
  end
end
