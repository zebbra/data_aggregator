defmodule DataAggregator.Records.Record.Changes.RelateCollectionFromImport do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    # In Ash 3.0, this raises(DBConnection.ConnectionError) could not checkout the connection owned by #PID<0.954.0>
    # Don't know why. Maybe because of the bulk?: false in Ash 3.0
    # See file lib/data_aggregator/records/record/changes/relate_import.ex
    import =
      changeset
      |> Changeset.get_argument(:import)
      |> Ash.load!([:collection], lazy?: true)

    Changeset.manage_relationship(
      changeset,
      :collection,
      import.collection,
      type: :append
    )
  end
end
