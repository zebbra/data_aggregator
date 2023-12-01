defmodule DataAggregator.Platform.Publication.Changes.SetExportedAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Platform.Publication.Export.exported/1` after the publish action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Publication.Export

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset |> Changeset.after_action(&set_exported/2)
  end

  defp set_exported(_changeset, export) do
    Export.set_exported(export)
  end
end
