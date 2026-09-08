defmodule DataAggregator.Records.ValidationRequest.Changes.SetValidatingBeforeTransaction do
  @moduledoc """
  Sets the Collectionstate to `:validating` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_validating/1)
  end

  defp set_validating(%Changeset{tenant: collection} = changeset) do
    if collection.state != :validating, do: Collection.set_validating!(collection)

    changeset
  end
end
