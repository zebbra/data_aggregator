defmodule DataAggregator.Checks.Admin do
  @moduledoc """
  Check if the user resource being accessed has the role "admin".
  """
  use Ash.Policy.SimpleCheck

  alias Ash.Resource.Actions

  require Logger

  @impl true
  def describe(_opts) do
    "accessed user resource s an admin"
  end

  @impl true
  def requires_original_data?(_, _), do: false

  @impl true
  def match?(nil, _, _), do: false

  @impl true
  def match?(_actor, context, _opts) do
    case get_entry(context.changeset, :roles, context.action) do
      nil ->
        Logger.error(
          "No :roles found on %User{} resource. You can use DataAggregator.Checks.Admin only in policies on the %User{} resource."
        )

        false

      roles when is_list(roles) ->
        Enum.member?(roles, "admin")

      _ ->
        false
    end
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
