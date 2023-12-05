defmodule DataAggregator.Platform.Publication.Changes.UpdateMapping do
  @moduledoc """
  Changeset hook to update the mapping of the export, to export the records with the given column headers
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    mapping = Changeset.get_argument(changeset, :mapping)

    if is_map(mapping) or mapping == nil do
      Changeset.change_attribute(changeset, :mapping, mapping)
    else
      Changeset.add_error(
        changeset,
        field: :mapping,
        message: "invalid mapping provided",
        value: mapping
      )
    end
  end
end
