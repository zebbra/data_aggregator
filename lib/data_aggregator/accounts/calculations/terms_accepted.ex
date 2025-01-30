defmodule DataAggregator.Accounts.Calculations.TermsAccepted do
  @moduledoc """
    This `Ash.Resource.Calculation` calculates if the terms are accepted.
  """
  use Ash.Resource.Calculation

  alias DataAggregator.Accounts

  @impl Ash.Resource.Calculation
  def calculate(users, _opts, _context) do
    Enum.map(users, &after?(&1.terms_accepted_at, Accounts.last_terms_update()))
  end

  def after?(nil, _last_terms_update), do: false

  def after?(terms_accepted_at, last_terms_update) do
    Date.compare(terms_accepted_at, last_terms_update) in [:gt, :eq]
  end
end
