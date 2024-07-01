defmodule DataAggregator.Records.Record.Changes.RelateCollectionFromImport do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    {:ok, import} =
      changeset
      |> Changeset.get_argument(:import)
      |> Ash.load([:collection], lazy?: true)

    Changeset.manage_relationship(
      changeset,
      :collection,
      import.collection,
      type: :append
    )
  end
end
