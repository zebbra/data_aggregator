defmodule DataAggregator.Records.Record.Changes.SetPublicationStale do
  @moduledoc """
  Calls `DataAggregator.Records.Record.update_fast_track_status/2` and `DataAggregator.Records.Record.update_approval_status/2`to update the
  publication states `fast_track_status` and `approval_status` to `stale` for a
  record which was changed during the import.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_publication_stale/2)
  end

  defp set_publication_stale(changeset, record) do
    if Changeset.changing_attributes?(changeset) do
      with {:ok, record} <- Record.update_fast_track_status(record, :stale) do
        Record.update_approval_status(record, :stale)

        Logger.debug("Publication states 'fast_track_status' and 'approval_status' set to ':stale'")

        {:ok, record}
      end
    end

    {:ok, record}
  end
end
