defmodule DataAggregator.Checks.WithRole do
  @moduledoc """
  Checks if the actor has at least one of the given roles.
  """

  use Ash.Policy.SimpleCheck

  @impl true
  def describe(options) do
    roles = Keyword.fetch!(options, :role)

    "actor.roles ∩ #{inspect(roles)}"
  end

  @impl true
  def requires_original_data?(_, _), do: false

  @impl true
  def match?(nil, _, _), do: false

  @impl true
  def match?(actor, _, options) do
    roles = Keyword.fetch!(options, :role)

    Enum.any?(actor_roles(actor), &Enum.member?(roles, &1))
  end

  defp actor_roles(%{roles: roles}), do: roles
  defp actor_roles(%{"roles" => roles}), do: roles
  defp actor_roles(_), do: []
end
