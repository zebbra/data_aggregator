defmodule DataAggregator.Platform.Publication.Changes.ExportRecords do
  @moduledoc """
  Changeset hook to export records for a consumer
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Publication.Export

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset |> Changeset.before_action(&export_records/1)
  end

  defp export_records(%Changeset{data: original_export} = changeset) do
    case original_export |> Export.publish() do
      {:ok, _export} -> changeset
      {:error, error} -> changeset |> add_error(error, original_export)
    end
  end

  defp add_error(changeset, error, export) do
    Logger.error("Error export records: #{inspect(error)}")
    export |> Export.set_failed()
    changeset |> Changeset.add_error(error)
  end
end
