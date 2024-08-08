defmodule DataAggregator.Records.Approval.Changes.SetOptionalAttributes do
  @moduledoc """
  Set optional fields for a approved_record according to its provided record. We mirror the record data on the raw layer to the approved_record for convenience reasons.
  This way we can easily access the record data from the approved_record. During encoding we overwrite all attributes which come back from the catalogs
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
      record -> assign_optional_attributes(changeset, record)
    end
  end

  defp add_missing_record_error(changeset) do
    Changeset.add_error(changeset, field: :record, message: "is required")

    changeset
  end

  defp assign_optional_attributes(changeset, record) do
    optional_values = Map.take(record, record_attribute_name_keys())

    Changeset.change_attributes(changeset, optional_values)
  end

  defp record_attribute_name_keys do
    Enum.map(DarwinCore.Schema.optional_prefixed_attributes(), & &1.name)
  end
end
