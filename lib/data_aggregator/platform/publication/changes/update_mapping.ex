defmodule DataAggregator.Platform.Publication.Changes.UpdateMapping do
  @moduledoc """
  Changeset hook to update the mapping of the export, to export the records with the given column headers
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    mapping = changeset |> Changeset.get_argument(:mapping)

    if is_map(mapping) or mapping == nil do
      changeset |> Changeset.change_attribute(:mapping, mapping)
    else
      changeset
      |> Changeset.add_error(
        field: :mapping,
        message: "invalid mapping provided",
        value: mapping
      )
    end
  end
end
