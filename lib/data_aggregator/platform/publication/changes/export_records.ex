defmodule DataAggregator.Platform.Publication.Changes.ExportRecords do
  @moduledoc """
  Changeset hook to export records
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform
  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &export_records/1)
  end

  defp export_records(%Changeset{data: original_export} = changeset) do
    export = Platform.load!(original_export, [:collection])
    collection = Records.load!(export.collection, [:records_to_publish_query])

    case Collection.export(export, collection.records_to_publish_query) do
      {:ok, export} -> add_success(changeset, export)
      {:error, error} -> add_error(changeset, error, export)
    end
  end

  defp add_error(changeset, error, export) do
    Logger.error("Error export records: #{inspect(error)}")
    Export.set_failed(export)
    Changeset.add_error(changeset, error)
  end

  defp add_success(changeset, export) do
    Logger.info("Successfully exported #{export.exported_count} records")

    changeset
  end
end
