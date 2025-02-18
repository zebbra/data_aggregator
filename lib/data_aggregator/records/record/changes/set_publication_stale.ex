defmodule DataAggregator.Records.Record.Changes.SetPublicationStale do
  @moduledoc """
  Sets the fast_track_status and validation_status to :stale if they are not :not_published and :not_validated respectively.
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
      :validation_status,
      expr(if validation_status == :not_validated, do: :not_validated, else: :stale)
    )
  end
end
