defmodule DataAggregator.Records.Record.Changes.SetOccurrenceIDAfterAction do
  @moduledoc """
  Sets the occ_occurrence_id to the record to the value of the catalog number (if not already set), after the action has completed.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_occurrence_id/2)
  end

  # if we don't have an occurrence_id, set it to the catalog number, because
  # we need the occurrence_id for publishing the record
  defp set_occurrence_id(_changeset, record) do
    if record.occ_occurrence_id != nil do
      Logger.debug("occurrence_id already set, skipping ...")

      {:ok, record}
    else
      Logger.debug("Setting occurrence_id ...")
      Record.update(record, %{occ_occurrence_id: record.mte_catalog_number})
    end
  end
end
