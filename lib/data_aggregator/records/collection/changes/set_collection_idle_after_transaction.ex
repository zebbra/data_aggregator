defmodule DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction do
  @moduledoc """
  Set the collection as idle after the action transaction is finished.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &set_collection_idle/2)
  end

  defp set_collection_idle(%Changeset{action: action, data: %{collection_id: collection_id}}, entity) do
    collection = Collection.get_by_id!(collection_id)

    if action.name in [:set_imported, :set_failed] do
      Logger.debug("Updating collections.records_count ...")

      records_count =
        Record
        |> Ash.Query.filter(collection_id == ^collection_id)
        |> Ash.count!()

      Collection.update!(collection, %{records_count: records_count})
    end

    Collection.set_idle(collection)

    entity
  end
end
