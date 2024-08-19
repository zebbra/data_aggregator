defmodule DataAggregator.Accounts.Helpers do
  @moduledoc false

  def has_role?(nil, _roles), do: false

  def has_role?(user, roles) when is_list(roles) do
    Enum.any?(user.roles, &(&1 in roles))
  end

  def has_role?(user, role) when is_binary(role) do
    role in user.roles
  end
end
