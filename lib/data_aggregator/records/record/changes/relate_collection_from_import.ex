defmodule DataAggregator.Records.Record.Changes.RelateCollectionFromImport do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    case Changeset.get_argument(changeset, :import) do
      %Import{collection_id: collection_id} ->
        Changeset.manage_relationship(changeset, :collection, %{id: collection_id}, type: :append)
    end
  end
end
