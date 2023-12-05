defmodule DataAggregator.Platform.Publication.Changes.ExportRecords do
  @moduledoc """
  Changeset hook to export records
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Publication.Export

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &export_records/1)
  end

  defp export_records(%Changeset{data: original_export} = changeset) do
    case Export.publish(original_export) do
      {:ok, _export} -> changeset
      {:error, error} -> add_error(changeset, error, original_export)
    end
  end

  defp add_error(changeset, error, export) do
    Logger.error("Error export records: #{inspect(error)}")
    Export.set_failed(export)
    Changeset.add_error(changeset, error)
  end
end
