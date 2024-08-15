defmodule DataAggregator.Checks.IsAdmin do
  @moduledoc false
  use Ash.Policy.SimpleCheck

  # This is used when logging a breakdown of how a policy is applied - see Logging below.
  def describe(_) do
    "actor has role 'admin'"
  end

  def match?(%{roles: roles} = _actor, _context, _opts) do
    Enum.member?(roles, "admin")
  end

  def match?(_, _, _), do: false
end
