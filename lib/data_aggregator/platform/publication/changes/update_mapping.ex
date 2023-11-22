defmodule DataAggregator.Platform.Publication.Changes.UpdateMapping do
  @moduledoc """
  Changeset hook to update the mapping of the export, to export the records with the given column headers
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    mapping = Changeset.get_argument(changeset, :mapping)

    Changeset.change_attribute(changeset, :mapping, mapping)
  end
end
