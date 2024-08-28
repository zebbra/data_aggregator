defmodule DataAggregator.Records.Export.Changes.SetCollectionExportingBeforeTransaction do
  @moduledoc """
  Set the collection as exporting before we start the export itself. If the collection is not
  idle, we will not allow the export to start.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, %{actor: actor}) do
    Changeset.before_transaction(changeset, fn changeset ->
      set_collection_exporting(changeset, actor)
    end)
  end

  defp set_collection_exporting(%Changeset{data: %{collection_id: collection_id}} = changeset, actor) do
    collection = Collection.get_by_id!(collection_id, actor: actor)

    case Collection.set_exporting(collection, actor: actor) do
      {:ok, _collection} ->
        changeset

      {:error, error} ->
        Changeset.add_error(changeset, error)
    end
  end
end
