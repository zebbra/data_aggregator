defmodule DataAggregator.Records.Collection.Changes.SetCollectionEncodingBeforeTransaction do
  @moduledoc """
  Set the collection as encoding before we start the encoding itself. If the collection is not
  idle, we will not allow the encoding to start.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_collection_encoding/1)
  end

  defp set_collection_encoding(%Changeset{data: %{id: id}} = changeset) do
    collection = Collection.get_by_id!(id)

    case Collection.set_encoding(collection) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end
end
