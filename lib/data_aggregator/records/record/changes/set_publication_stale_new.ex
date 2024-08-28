defmodule DataAggregator.Records.Record.Changes.SetPublicationStaleNew do
  @moduledoc """
  Calls `DataAggregator.Records.Record.update_fast_track_status/2` and `DataAggregator.Records.Record.update_approval_status/2`to update the
  publication states `fast_track_status` and `approval_status` to `stale` for a
  record which was changed during the import.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.atomic_update(
      :fast_track_status,
      expr(if fast_track_status == :not_published, do: :not_published, else: :stale)
    )
    |> Changeset.atomic_update(
      :approval_status,
      expr(if approval_status == :not_approved, do: :not_approved, else: :stale)
    )
  end
end
