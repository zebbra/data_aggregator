defmodule DataAggregator.Records.ImageUpload.Changes.SetCollectionMappingBeforeTransaction do
  @moduledoc """
  Set the collection as mapping before we start the image upload mapping itself. If the collection is not
  idle, we will not allow the import to start.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_collection_mapping/1)
  end

  defp set_collection_mapping(%Changeset{data: %{collection_id: collection_id}} = changeset) do
    collection = Collection.get_by_id!(collection_id)

    case Collection.set_mapping(collection) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end
end
