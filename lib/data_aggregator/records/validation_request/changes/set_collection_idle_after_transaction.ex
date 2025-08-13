defmodule DataAggregator.Records.ValidationRequest.Changes.SetCollectionIdleAfterTransaction do
  @moduledoc """
  Sets the collection back to idle after transaction is completed
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &set_collection_idle/2)
  end

  defp set_collection_idle(_changeset, {:error, error}) do
    {:error, error}
  end

  defp set_collection_idle(_changeset, {:ok, vr}) do
    collection = Collection.get_by_id!(vr.collection_id)

    Collection.set_idle(collection)

    {:ok, vr}
  end
end
