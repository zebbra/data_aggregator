defmodule DataAggregator.Records.Import.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
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
        |> bulk_import(import)
        |> handle_import(changeset)

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end

  defp bulk_import(stream, import) do
    Record.bulk_import(import, stream)
  end

  defp handle_import({:ok, stream}, changeset) do
    Enum.reduce(stream, changeset, fn
      {:ok, _record}, changeset ->
        changeset

      {:error, error}, changeset ->
        Logger.warning("Error importing record: #{inspect(error)}")
        changeset |> Changeset.add_error(error)
    end)
  end

  defp handle_import({:error, error}, changeset) do
    Logger.error("Error importing record: #{inspect(error)}")
    changeset
  end

  defp stream_records(import) do
    with {:ok, import} <- DataAggregator.Records.load(import, attachment_data: [mapped: true]) do
      {:ok, import.attachment_data |> Explorer.DataFrame.to_rows_stream()}
    end
  end
end
