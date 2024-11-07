defmodule DataAggregator.Records.Encoding.Changes.SetMandatoryAttributes do
  @moduledoc """
  Set mandatory fields for a encoded_record according to its provided record.
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

    changeset
    |> Changeset.change_attributes(mandatory_values)
    |> Changeset.change_attribute(:record_id, record.id)
    |> Changeset.change_attribute(:collection_id, record.collection_id)
  end

  defp record_attribute_name_keys do
    Enum.map(DarwinCore.Schema.mandatory_prefixed_attributes(), & &1.name)
  end
end
