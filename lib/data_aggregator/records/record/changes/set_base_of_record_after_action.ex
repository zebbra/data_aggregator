defmodule DataAggregator.Records.Record.Changes.SetBasisOfRecordAfterAction do
  @moduledoc """
  Sets the occ_occurrence_id to the record to the value of the catalog number (if not already set), after the action has completed.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_base_of_record/2)
  end

  # if we don't have an basis_of_record, set it to the "PreservedSpecimen", because
  # we need it for publishing the record
  defp set_base_of_record(_changeset, record) do
    if record.oth_basis_of_record != nil do
      Logger.debug("basis_of_record already set, skipping ...")

      {:ok, record}
    else
      Logger.debug("Setting basis_of_record ...")
      Record.update(record, %{oth_basis_of_record: "PreservedSpecimen"})
    end
  end
end
