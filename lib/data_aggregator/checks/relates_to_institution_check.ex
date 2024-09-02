defmodule DataAggregator.Checks.RelatesToInstitutionCheck do
  @moduledoc """
  Checks if the actor is related to the institution via the institution_id field
  and the given foreign key.
  """
  use Ash.Policy.SimpleCheck

  alias Ash.Resource.Actions

  @impl true
  def describe(options) do
    foreign_key = Keyword.fetch!(options, :foreign_key)
    path = Keyword.fetch!(options, :path)

    reference_path = Enum.join(path ++ [foreign_key], ".")

    "actor is related to the institution by foreign key #{reference_path}"
  end

  @impl true
  def requires_original_data?(_, _), do: false

  @impl true
  def match?(nil, _, _), do: false

  @impl true
  def match?(actor, context, options) do
    foreign_key = Keyword.fetch!(options, :foreign_key)
    path = Keyword.fetch!(options, :path)

    institution_id = get_institution_id(context.changeset, path, foreign_key, context.action)
    institution_id == actor_institution_id(actor) || institution_id == nil
  end

  defp actor_institution_id(%{institution_id: institution_id}), do: institution_id
  defp actor_institution_id(%{"institution_id" => institution_id}), do: institution_id
  defp actor_institution_id(_), do: nil

  defp get_institution_id(changeset, [], foreign_key, _action) do
    Ash.Changeset.get_attribute(changeset, foreign_key)
  end

  defp get_institution_id(changeset, path, foreign_key, action) do
    [root_key | rest] = path
    rest = rest ++ [foreign_key]

    entry = get_entry(changeset, root_key, action)

    Enum.reduce_while(rest, entry, fn key, acc ->
      case Map.get(acc, key) do
        nil -> {:halt, nil}
        value -> {:cont, value}
      end
    end)
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
