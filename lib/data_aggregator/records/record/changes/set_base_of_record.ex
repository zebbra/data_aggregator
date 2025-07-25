defmodule DataAggregator.Records.Record.Changes.SetBasisOfRecord do
  @moduledoc """
  Sets the occ_occurrence_id to the record to the value of the catalog number (if not already set), after the action has completed.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    set_base_of_record(changeset)
  end

  # if we don't have an basis_of_record, set it to the "PreservedSpecimen", because
  # we need it for publishing the record
  defp set_base_of_record(changeset) do
    oth_basis_of_record = Changeset.get_argument_or_attribute(changeset, :oth_basis_of_record)

    if oth_basis_of_record == nil do
      # Logger.debug("Setting basis_of_record ...")
      Changeset.change_attribute(changeset, :oth_basis_of_record, "PreservedSpecimen")
    else
      Logger.debug("basis_of_record already set, skipping ...")

      changeset
    end
  end
end
