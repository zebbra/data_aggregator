defmodule DataAggregator.Records.Publication.Changes.SetCollectionPublishingBeforeTransaction do
  @moduledoc """
  Set the collection as either fast_track_publishing or approving before we start the
  publication itself. If the collection is not idle, we will not allow the publication to start.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_collection_publishing/1)
  end

  defp set_collection_publishing(%Changeset{data: %{collection_id: collection_id, channel: channel}} = changeset)
       when channel in [:approval, "approval"] do
    collection = Collection.get_by_id!(collection_id)

    case Collection.set_approving(collection) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end

  defp set_collection_publishing(%Changeset{data: %{collection_id: collection_id, channel: channel}} = changeset)
       when channel in [:fast_track, "fast_track"] do
    collection = Collection.get_by_id!(collection_id)

    case Collection.set_fast_track_publishing(collection) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end
end
