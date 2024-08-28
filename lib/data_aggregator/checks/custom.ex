defmodule DataAggregator.Checks.Custom do
  @moduledoc "The custom global authorization checks provided by DataAggregator"

  alias Ash.Policy.Check
  alias DataAggregator.Checks.RelatesToInstitutionCheck
  alias DataAggregator.Checks.RelatesToInstitutionFilter

  @doc """
  Applies a filter to ensure that the actor belongs to the institution via the
  institution_id field and the given foreign key.
  """
  @spec relates_to_institution_filter(
          path_or_foreign_key :: atom() | list(atom()),
          foreign_key :: atom()
        ) ::
          Check.ref()

  def relates_to_institution_filter(path, foreign_key) do
    {RelatesToInstitutionFilter, foreign_key: foreign_key, path: List.wrap(path)}
  end

  def relates_to_institution_filter(foreign_key) do
    {RelatesToInstitutionFilter, foreign_key: foreign_key, path: []}
  end

  @doc """
  Checks that the actor belongs to the institution via the institution_id field
  and the given foreign key.
  """
  @spec relates_to_institution_check(foreign_key :: atom()) :: Check.ref()
  def relates_to_institution_check(foreign_key) do
    {RelatesToInstitutionCheck, foreign_key: foreign_key}
  end

  @doc """
  Check if the actor has at least one of the given roles.
  """
  @spec with_role(role :: String.t() | list(String.t())) :: Check.ref()
  def with_role(role) do
    {DataAggregator.Checks.WithRole, role: List.wrap(role)}
  end

  @doc """
  Check if the actor is the same as the resource being accessed.
  """
  @spec it_is_myself() :: Check.ref()
  def it_is_myself do
    DataAggregator.Checks.Myself
  end
end
