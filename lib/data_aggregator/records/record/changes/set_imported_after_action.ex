defmodule DataAggregator.Records.Record.Changes.SetImportedAfterAction do
  @moduledoc """
  Calls `DataAggregator.Records.Record.set_imported/1` after the action has completed
  to update the state to `:imported`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_imported/2)
  end

  defp set_imported(_changeset, record) do
    Logger.info("Setting record to imported ...")
    Record.set_imported(record)
  end
end
