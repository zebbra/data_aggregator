defmodule DataAggregator.Records.Collection.Changes.SetDeletingBeforeTransaction do
  @moduledoc """
  Sets the state to `:deleting` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_deleting/1)
  end

  defp set_deleting(%Changeset{data: collection} = changeset) do
    case Collection.set_deleting(collection) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end
end
