defmodule DataAggregator.Checks.RelatesToInstitutionFilter do
  @moduledoc """
  Applies a filter to ensure that the actor is related to the institution via
  the institution_id field and the given foreign key.
  """

  use Ash.Policy.FilterCheck

  @impl true
  def describe(options) do
    foreign_key = Keyword.fetch!(options, :foreign_key)
    path = Keyword.fetch!(options, :path)

    reference_path = Enum.join(path ++ [foreign_key], ".")

    "actor is related to the institution by foreign key #{reference_path}"
  end

  @impl true
  def filter(_actor, _context, options) do
    foreign_key = Keyword.fetch!(options, :foreign_key)
    path = Keyword.fetch!(options, :path)

    expr(^ref(path, foreign_key) == ^actor(:institution_id))
  end
end
