defmodule DataAggregator.Records.Import.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset |> Changeset.before_action(&import_records/1)
  end

  defp import_records(%Changeset{data: import} = changeset) do
    Logger.info("Importing records for #{inspect(import)} ...")

    case stream_records(import) do
      {:ok, stream} ->
        stream
        |> bulk_import(import)
        |> reduce_import_stream(changeset)
        |> handle_import_result()

      {:error, error} ->
        changeset |> add_error(error)
    end
  end

  defp bulk_import(stream, import) do
    Record.bulk_import(import, stream)
  end

  defp reduce_import_stream({:ok, stream}, changeset) do
    Enum.reduce(stream, {0, 0, changeset}, fn
      {:ok, _record}, {imported, failed, changeset} ->
        {imported + 1, failed, changeset}

      {:error, error}, {imported, failed, changeset} ->
        changeset = changeset |> add_error(error)
        {imported, failed + 1, changeset}
    end)
  end

  defp reduce_import_stream({:error, error}, changeset) do
    changeset = changeset |> add_error(error)
    {0, 0, changeset}
  end

  defp handle_import_result({imported, failed, changeset}) do
    total = imported + failed
    message = "Imported #{imported}/#{total} records (#{failed} failed)"

    case failed do
      0 -> Logger.info(message)
      _ -> Logger.error(message)
    end

    changeset
  end

  defp stream_records(import) do
    with {:ok, import} <- DataAggregator.Records.load(import, attachment_data: [mapped: true]),
         stream <- Explorer.DataFrame.to_rows_stream(import.attachment_data),
         do: {:ok, stream}
  end

  defp add_error(changeset, error) do
    Logger.error("Error importing record: #{inspect(error)}")
    changeset |> Changeset.add_error(error)
  end
end
