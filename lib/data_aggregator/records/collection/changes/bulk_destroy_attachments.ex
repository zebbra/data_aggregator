defmodule DataAggregator.Records.Collection.Changes.BulkSoftDeleteAttachments do
  @moduledoc """
  Changeset for soft deleting attachments associated with a collection.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment

  require Ash.Query

  @doc """
  Creates a changeset for soft deleting attachments associated with a collection.
  """
  @impl true
  def change(changeset, _opts, %{actor: actor}) do
    Changeset.before_action(changeset, fn changeset ->
      collection_id = changeset.data.id

      Attachment
      |> Ash.Query.filter(collection_id == ^collection_id)
      |> Ash.bulk_destroy!(:destroy, %{},
        strategy: :atomic_batches,
        return_errors?: true,
        return_records?: true,
        actor: actor
      )

      changeset
    end)
  end
end
