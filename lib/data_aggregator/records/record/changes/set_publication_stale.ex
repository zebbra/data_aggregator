defmodule DataAggregator.Records.Record.Changes.SetPublicationStale do
  @moduledoc """
  Sets the fast_track_status and approval_status to :stale if they are not :not_published and :not_approved respectively.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.atomic_update(
      :fast_track_status,
      expr(
        if fast_track_status == :not_published or fast_track_status == "not_published",
          do: :not_published,
          else: :stale
      )
    )
    |> Changeset.atomic_update(
      :approval_status,
      expr(
        if approval_status == :not_approved or approval_status == "not_approved",
          do: :not_approved,
          else: :stale
      )
    )
  end
end
