defmodule DataAggregator.Checks.RelatesToInstitutionCheck do
  @moduledoc """
  Checks if the actor is related to the institution via the institution_id field
  and the given foreign key.
  """
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(options) do
    foreign_key = Keyword.fetch!(options, :foreign_key)

    "actor is related to the institution by foreign key #{foreign_key}"
  end

  @impl true
  def requires_original_data?(_, _), do: false

  @impl true
  def match?(nil, _, _), do: false

  @impl true
  def match?(actor, context, options) do
    foreign_key = Keyword.fetch!(options, :foreign_key)

    Ash.Changeset.get_attribute(context.changeset, foreign_key) == actor.institution_id
  end
end
