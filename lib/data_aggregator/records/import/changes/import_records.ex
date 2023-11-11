defmodule DataAggregator.Records.Import.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import.Mapping
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.before_action(&import_records/1, append: true)
  end

  defp import_records(%Changeset{data: import} = changeset) do
    case stream_records(import) do
      {:ok, stream} ->
        stream
        |> apply_mapping(import)
        |> bulk_import(import)
        |> handle_import(changeset)

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end

  defp apply_mapping(stream, import) do
    stream |> Stream.map(&Mapping.map_params(&1, import.columns))
  end

  defp bulk_import(stream, import) do
    Record.bulk_import(import, stream)
  end

  defp handle_import({:ok, %Ash.BulkResult{}}, changeset) do
    changeset
  end

  defp handle_import({:error, error}, changeset) do
    Logger.error("Error importing record: #{inspect(error)}")
    changeset
  end

  defp stream_records(import) do
    with {:ok, import} <- DataAggregator.Records.load(import, attachment: [:url]),
         {:ok, data} <- Explorer.DataFrame.from_csv(import.attachment.url) do
      {:ok, Explorer.DataFrame.to_rows_stream(data)}
    end
  end
end
