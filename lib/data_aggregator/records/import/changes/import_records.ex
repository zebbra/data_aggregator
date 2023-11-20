defmodule DataAggregator.Records.Import.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.BulkResult
  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset |> Changeset.before_action(&import_records/1)
  end

  defp import_records(%Changeset{data: import} = changeset) do
    Logger.info("Importing records for #{inspect(import.id)} ...")

    case rows_stream(import) do
      {:ok, rows} -> changeset |> import_in_chunks(rows)
      {:error, error} -> changeset |> add_error(error)
    end
  end

  defp import_in_chunks(%Changeset{data: import} = changeset, rows) do
    chunk_size = Records.import_batch_size()
    Logger.info("Importing records in chunks of #{chunk_size} rows ...")

    # make sure collection is loaded to avoid N+1 queries
    import = import |> Records.load!([:collection], lazy?: true)

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&import_chunk(import, &1))
    |> reduce_import_results(changeset)
    |> error_if_nothing_imported()
  end

  defp import_chunk(import, {chunk, index}) do
    Logger.info("Importing chunk ##{index} with #{length(chunk)} rows ...")

    valid_row? = fn row ->
      changeset = Record.changeset_to_import(import, row)
      changeset.valid?
    end

    max_concurrency = Records.import_max_concurrency()

    {valid, invalid} =
      chunk
      |> Task.async_stream(&{&1, valid_row?.(&1)}, max_concurrency: max_concurrency)
      |> Enum.reduce({[], []}, fn
        {:ok, {row, true}}, {valid, invalid} -> {[row | valid], invalid}
        {:ok, {row, false}}, {valid, invalid} -> {valid, [row | invalid]}
      end)

    if length(invalid) > 0 do
      Logger.warning("#{length(invalid)} invalid row(s) dropped from chunk!")
    end

    Logger.info("Importing #{length(valid)}/#{length(invalid)} valid rows ...")
    res = Record.bulk_import!(import, Enum.reverse(valid))

    {res, length(valid), length(invalid)}
  end

  def reduce_import_results(results, changeset) do
    Enum.reduce_while(results, changeset, fn
      {%BulkResult{status: :success}, imported, invalid}, changeset ->
        changeset = changeset |> report_progress(imported, invalid)
        {:cont, changeset}

      {%BulkResult{errors: errors}, _, _}, changeset ->
        changeset = errors |> Enum.reduce(changeset, &add_error(&1, &2))
        {:halt, changeset}
    end)
  end

  defp report_progress(changeset, imported, invalid) do
    Logger.debug("Batch successful (#{imported} imported, #{invalid} skipped)")

    %Changeset{data: import} = changeset

    add_progress = fn -> Import.add_progress!(import, imported, invalid) end

    import =
      if Records.async_import_progress?() do
        add_progress |> Task.async() |> Task.await()
      else
        add_progress.()
      end

    %{changeset | data: import}
  end

  defp error_if_nothing_imported(changeset) do
    %Changeset{data: import} = changeset

    if import.imported_count == 0 do
      changeset |> add_error("No records imported!")
    else
      changeset
    end
  end

  defp rows_stream(import) do
    with {:ok, import} <- DataAggregator.Records.load(import, attachment_data: [mapped: true]),
         stream <- Explorer.DataFrame.to_rows_stream(import.attachment_data),
         do: {:ok, stream}
  end

  defp add_error(changeset, error) do
    Logger.error("Error importing records: #{inspect(error)}")
    changeset |> Changeset.add_error(error)
  end
end
