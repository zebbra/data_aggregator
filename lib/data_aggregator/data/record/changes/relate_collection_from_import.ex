defmodule DataAggregator.Data.Record.Changes.RelateCollectionFromImport do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Import

  def change(%Changeset{} = changeset, _opts, _ctx) do
    case Changeset.get_argument(changeset, :import) do
      nil ->
        changeset

      %Import{collection: collection} ->
        changeset
        |> Changeset.manage_relationship(:collection, collection, type: :append)
    end
  end
end
