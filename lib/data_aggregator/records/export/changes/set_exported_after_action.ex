defmodule DataAggregator.Records.Export.Changes.SetExportedAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Export.set_exported/1` after the export action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Export

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_exported/2)
  end

  defp set_exported(_changeset, export) do
    Export.set_exported(export)
  end
end
