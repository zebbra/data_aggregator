defmodule DataAggregator.Records.Record.Changes.SetOccurrenceID do
  @moduledoc """
  Sets the occ_occurrence_id to the record to the value of the catalog number (if not already set), after the action has completed.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    set_occurrence_id(changeset)
  end

  # if we don't have an occurrence_id, set it to the catalog number, because
  # we need the occurrence_id for publishing the record
  defp set_occurrence_id(changeset) do
    occ_occurrence_id = Changeset.get_argument_or_attribute(changeset, :occ_occurrence_id)

    if occ_occurrence_id == nil do
      # Logger.debug("Setting occurrence_id ...")

      mte_catalog_number = Changeset.get_argument_or_attribute(changeset, :mte_catalog_number)
      Changeset.change_attribute(changeset, :occ_occurrence_id, mte_catalog_number)
    else
      Logger.debug("occurrence_id already set, skipping ...")

      changeset
    end
  end
end
