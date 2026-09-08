defmodule DataAggregator.Records.ValidationResponse.Changes.SetMandatoryAttributes do
  @moduledoc """
  Set mandatory fields for a validation_record according to its provided record.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.DarwinCore

  @impl true
  def batch_change(changesets, opts, ctx) do
    Enum.map(changesets, &change(&1, opts, ctx))
  end

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    case Changeset.get_argument(changeset, :record) do
      nil -> add_missing_record_error(changeset)
      record -> assign_mandatory_attributes(changeset, record)
    end
  end

  defp add_missing_record_error(changeset) do
    Changeset.add_error(changeset, field: :record, message: "is required")

    changeset
  end

  defp assign_mandatory_attributes(changeset, record) do
    mandatory_values = Map.take(record, record_attribute_name_keys())

    # take non-nil values from changeset attributes, otherwise use the mandatory values from the record
    result =
      Map.merge(
        mandatory_values,
        changeset.attributes
        |> Map.take(Map.keys(mandatory_values))
        |> Map.reject(fn {_k, v} -> is_nil(v) end)
      )

    Changeset.change_attributes(changeset, result)
  end

  defp record_attribute_name_keys do
    Enum.map(DarwinCore.Schema.mandatory_prefixed_attributes(), & &1.name)
  end
end
