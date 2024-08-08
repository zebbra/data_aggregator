defmodule DataAggregator.Records.Record.Changes.RelateCollectionFromImport do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    import = Changeset.get_argument(changeset, :import)

    Changeset.manage_relationship(
      changeset,
      :collection,
      import.collection,
      type: :append
    )
  end
end
