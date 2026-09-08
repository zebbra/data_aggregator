defmodule DataAggregator.Checks.Myself do
  @moduledoc """
  Check if the actor is the same as the resource being accessed.
  """
  use Ash.Policy.SimpleCheck

  alias Ash.Resource.Actions

  @impl true
  def describe(_opts) do
    "it's the actor"
  end

  @impl true
  def requires_original_data?(_, _), do: true

  @impl true
  def match?(nil, _, _), do: false

  @impl true
  def match?(%{id: actor_id}, context, _opts) do
    user_id = get_entry(context.changeset, :id, context.action)
    actor_id == user_id
  end

  defp get_entry(changeset, key, %Actions.Update{}) do
    Ash.Changeset.get_data(changeset, key) || %{}
  end

  defp get_entry(changeset, key, %Actions.Destroy{}) do
    Ash.Changeset.get_data(changeset, key) || %{}
  end

  defp get_entry(changeset, key, _action) do
    Ash.Changeset.get_argument(changeset, key) || %{}
  end
end
