defmodule DataAggregator.Records.Import.Changes.SetImportedAfterAction do
  @moduledoc """
  Calls `DataAggregator.Records.Import.set_imported/1` after the action has completed
  to update the state to `:imported`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_imported/2)
  end

  defp set_imported(_changeset, import) do
    Logger.debug("Setting import to imported ...")
    Import.set_imported(import)
  end
end
