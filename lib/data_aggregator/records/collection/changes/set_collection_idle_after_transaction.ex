defmodule DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction do
  @moduledoc """
  Set the collection as idle after the action transaction is finished.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &set_collection_idle/2)
  end

  defp set_collection_idle(%Changeset{data: %{collection_id: collection_id}}, entity) do
    collection = Collection.get_by_id!(collection_id)
    Collection.set_idle(collection)

    entity
  end
end
