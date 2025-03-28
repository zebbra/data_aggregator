defmodule DataAggregator.Records.Import.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  import DataAggregator.Records.Import.Helpers

  alias Ash.BulkResult
  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &import_records(&1, ctx), append?: true)
  end

  defp import_records(%Changeset{data: import} = changeset, ctx) do
    if changeset.valid? do
      Logger.info("Importing records for #{inspect(import.id)} ...")

      case rows_stream(import) do
        {:ok, rows} -> import_in_chunks(changeset, rows, ctx)
        {:error, error} -> add_error(changeset, error)
      end
    else
      Logger.warning("Import #{inspect(import.id)} is invalid. Skipped...")
      changeset
    end
  end

  defp import_in_chunks(%Changeset{data: import} = changeset, rows, ctx) do
    chunk_size = Records.import_batch_size()

    Logger.info("Importing records in chunks of #{chunk_size} rows ...")

    # make sure collection is loaded to avoid N+1 queries
    import = Ash.load!(import, [:collection], lazy?: true)

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&import_chunk(import, &1, ctx))
    |> reduce_import_results(changeset)
    |> error_if_nothing_imported()
  end

  defp import_chunk(import, {chunk, index}, %{actor: actor, tenant: tenant}) do
    max_concurrency = Records.import_max_concurrency()

    Logger.info("Importing chunk ##{index} with #{length(chunk)} rows (concurrency: #{max_concurrency}) ...")

    {valid, invalid} =
      chunk
      |> Task.async_stream(&{&1, valid_import_row?(import, &1)},
        max_concurrency: max_concurrency,
        timeout: to_timeout(second: 30)
      )
      |> Enum.reduce({[], []}, fn
        {:ok, {row, true}}, {valid, invalid} -> {[row | valid], invalid}
        {:ok, {row, false}}, {valid, invalid} -> {valid, [row | invalid]}
      end)

    if length(invalid) > 0 do
      Logger.warning("#{length(invalid)} invalid row(s) dropped from chunk!")
    end

    Logger.info("Importing #{length(valid)} valid rows ...")

    res =
      Record.bulk_import!(import, Enum.reverse(valid),
        actor: actor,
        authorize?: false,
        tenant: tenant
      )

    {res, length(valid), length(invalid)}
  end

  def reduce_import_results(results, changeset) do
    Enum.reduce_while(results, changeset, fn
      {%BulkResult{status: :success}, imported, invalid}, changeset ->
        changeset = report_progress(changeset, imported, invalid)
        {:cont, changeset}

      {%BulkResult{errors: errors}, _, _}, changeset ->
        changeset = Enum.reduce(errors, changeset, &add_error(&1, &2))
        {:halt, changeset}
    end)
  end

  defp report_progress(changeset, imported, invalid) do
    Logger.debug("Batch successful (#{imported} imported, #{invalid} skipped)")

    %Changeset{data: import} = changeset

    add_progress = fn -> Import.add_import_progress!(import, imported) end

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

    if import.rows_imported_count == 0 do
      add_error(changeset, "No records imported!")
    else
      changeset
    end
  end

  defp rows_stream(import) do
    with {:ok, import} <- Ash.load(import, attachment_data: [mapped: true]) do
      stream = Explorer.DataFrame.to_rows_stream(import.attachment_data)
      {:ok, stream}
    end
  end

  defp add_error(changeset, error) do
    Logger.warning("Error importing records: #{inspect(error)}")
    Changeset.add_error(changeset, error)
  end
end
