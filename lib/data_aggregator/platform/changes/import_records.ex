defmodule DataAggregator.Platform.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Import

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.before_action(&import_records/1, append: true)
  end

  defp import_records(%Changeset{data: import} = changeset) do
    case stream_records(import) do
      {:ok, stream} ->
        stream
        |> Stream.map(&Import.import_record(import, &1))
        |> Enum.reduce(changeset, &handle_import/2)

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end

  defp handle_import({:ok, _import}, changeset) do
    changeset
  end

  defp handle_import({:error, error}, changeset) do
    Logger.error("Error importing record: #{inspect(error)}")
    changeset
  end

  defp stream_records(import) do
    with {:ok, import} <- DataAggregator.Platform.load(import, attachment: [:url]),
         {:ok, data} <- Explorer.DataFrame.from_csv(import.attachment.url) do
      {:ok, Explorer.DataFrame.to_rows_stream(data)}
    end
  end
end
