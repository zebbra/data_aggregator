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
    %Changeset{data: collection} = changeset

    Collection.set_deleting(collection)

    changeset
  end
end
