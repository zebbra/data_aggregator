defmodule DataAggregator.Records.Record.Changes.DecrementCollectionRecordsCountAfterAction do
  @moduledoc """
  This change decrements the `records_count` of the collection after the action is completed
  and the record is successfully deleted.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &decrement_collection_records_count/2)
  end

  defp decrement_collection_records_count(_changeset, record) do
    Collection.decrement_records_count!(record.collection_id)

    {:ok, record}
  end
end
