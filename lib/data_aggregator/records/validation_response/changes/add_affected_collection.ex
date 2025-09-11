defmodule DataAggregator.Records.ValidationResponse.Changes.AddAffectedCollection do
  @moduledoc """
  Adds a collection to affected_collections by creating a join table record directly.
  Uses upsert to avoid duplicate key errors on the database level
  """

  use Ash.Resource.Change

  alias DataAggregator.Records.ValidationResponseCollection

  @impl true
  def change(changeset, _opts, _context) do
    collection = Ash.Changeset.get_argument(changeset, :collection)

    # Create join table record with upsert - this handles duplicates at DB level
    ValidationResponseCollection.create!(%{
      validation_response_id: changeset.data.id,
      collection_id: collection.id
    })

    changeset
  end
end
