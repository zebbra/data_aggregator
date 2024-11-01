defmodule DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction do
  @moduledoc """
  Set the collection as idle after the action transaction is finished.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  require Ash.Changeset
  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &set_collection_idle/2)
  end

  defp set_collection_idle(%Changeset{valid?: false}, entity) do
    entity
  end

  defp set_collection_idle(%Changeset{action: action, data: data, valid?: true}, entity) do
    # This change might be called from a record change, so we need to get the
    # collection_id from the data or the id of the entity if it's a collection change
    collection_id = Map.get(data, :collection_id, Map.get(data, :id))
    collection = Collection.get_by_id!(collection_id)

    cond do
      collection.state == :approving ->
        active_approvals =
          Publication
          |> Ash.Query.set_tenant(collection)
          |> Ash.Query.filter(state in [:queued, :running])
          |> Ash.count!()

        if active_approvals == 0 do
          Collection.set_idle(collection)
        end

      collection.state == :encoding ->
        Collection.set_idle_encoding(collection)

      collection.state != :idle ->
        if action.name in [:set_imported, :set_failed] do
          Logger.debug("Updating collections.records_count ...")

          records_count =
            Record
            |> Ash.Query.set_tenant(collection)
            |> Ash.Query.filter(collection_id == ^collection_id)
            |> Ash.count!()

          Collection.update!(collection, %{records_count: records_count})
        end

        Collection.set_idle(collection)

      true ->
        nil
    end

    entity
  end
end
