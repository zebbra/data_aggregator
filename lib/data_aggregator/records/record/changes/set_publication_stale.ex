defmodule DataAggregator.Records.Record.Changes.SetPublicationStale do
  @moduledoc """
  Sets the publication_status and validation_status in case of stale event.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.atomic_update(
      :publication_status,
      expr(if publication_status == :not_published, do: :not_published, else: :stale)
    )
    |> Changeset.atomic_update(
      :validation_status,
      expr(:unknown)
    )
  end
end
