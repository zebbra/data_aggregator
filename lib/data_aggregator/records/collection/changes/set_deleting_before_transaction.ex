defmodule DataAggregator.Records.Collection.Changes.SetDeletingBeforeTransaction do
  @moduledoc """
  Sets the state to `:deleting` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, %{actor: actor}) do
    Changeset.before_transaction(changeset, fn changeset -> set_deleting(changeset, actor) end)
  end

  defp set_deleting(%Changeset{data: collection} = changeset, actor) do
    case Collection.set_deleting(collection, actor: actor) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end
end
