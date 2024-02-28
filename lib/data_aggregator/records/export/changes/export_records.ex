defmodule DataAggregator.Records.Changes.ExportRecords do
  @moduledoc """
  Changeset hook to export records
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &export_records/1, append?: true)
  end

  defp export_records(%Changeset{data: original_export} = changeset) do
    export = Records.load!(original_export, [:collection])

    case Collection.export(export) do
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
    export = Export.get_by_id!(export.id)
    Logger.info("Successfully exported #{export.exported_count} records")

    changeset
  end
end
