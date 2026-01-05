defmodule DataAggregator.Records.Collection.Changes.SetDeleting do
  @moduledoc """
  Sets the state to `:deleting` while the collection is being deleted.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, fn changeset ->
      %Changeset{data: collection} = changeset

      Collection.set_deleting(collection)

      changeset
    end)
  end
end
