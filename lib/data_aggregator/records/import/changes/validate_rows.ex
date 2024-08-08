defmodule DataAggregator.Records.Import.Changes.ValidateRows do
  @moduledoc """
  Ash change to validate the import.
  """

  use Ash.Resource.Change

  import DataAggregator.Records.Import.Helpers

  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &validate_rows/1, append?: true)
  end

  defp validate_rows(%Changeset{data: import} = changeset) do
    Logger.debug("Validating rows for #{inspect(import.id)} ...")

    case rows_stream(import) do
      {:ok, rows} -> validate_in_chunks(changeset, rows)
      {:error, error} -> add_error(changeset, error)
    end
  end

  defp validate_in_chunks(%Changeset{data: import} = changeset, rows) do
    chunk_size = Records.import_batch_size()
    Logger.debug("Validating rows in chunks of #{chunk_size} rows ...")

    # make sure collection is loaded to avoid N+1 queries
    import = Ash.load!(import, [:collection], lazy?: true)

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&validate_chunk(import, &1))
    |> reduce_validation_results(changeset)
  end

  defp validate_chunk(import, {chunk, index}) do
    Logger.debug("Validating chunk ##{index} with #{length(chunk)} rows ...")

    max_concurrency = Records.import_max_concurrency()

    {valid, invalid, errors} =
      chunk
      |> Task.async_stream(&validate_import_row(import, &1), max_concurrency: max_concurrency)
      |> Enum.reduce({0, 0, []}, fn
        {:ok, []}, {valid, invalid, all_errors} -> {valid + 1, invalid, all_errors}
        {:ok, errors}, {valid, invalid, all_errors} -> {valid, invalid + 1, [errors | all_errors]}
      end)

    {{valid, invalid}, errors |> Enum.reverse() |> List.flatten()}
  end

  def reduce_validation_results(results, %Changeset{data: import} = changeset) do
    {path, error_log_file} = open_error_log_file(import)

    changeset =
      Enum.reduce_while(results, changeset, fn
        {counts, []}, changeset ->
          changeset = report_progress(changeset, counts)
          {:cont, changeset}

        {counts, errors}, changeset ->
          write_error_log_file(error_log_file, errors)

          changeset = report_progress(changeset, counts)
          {:cont, changeset}
      end)

    upload_error_log_file!(path, import)

    valid = Changeset.get_attribute(changeset, :rows_valid_count)
    invalid = Changeset.get_attribute(changeset, :rows_invalid_count)
    total = valid + invalid

    case {valid, invalid} do
      {_, 0} ->
        Logger.debug("All #{valid} rows are valid. Marking import as valid...")
        changeset

      {_, _} ->
        Logger.warning("Found #{invalid}/#{total} invalid rows. Adding error to changeset...")
        Changeset.add_error(changeset, "Found #{invalid}/#{total} invalid rows")
    end
  end

  defp report_progress(changeset, {valid, invalid}) do
    Logger.debug("Batch validated (#{valid} valid, #{invalid} invalid)")

    %Changeset{data: import} = changeset

    add_progress = fn -> Import.add_validation_progress!(import, valid, invalid) end

    import =
      if Records.async_import_progress?() do
        add_progress |> Task.async() |> Task.await()
      else
        add_progress.()
      end

    %{changeset | data: import}
  end

  defp rows_stream(import) do
    with {:ok, import} <- Ash.load(import, attachment_data: [mapped: true]) do
      stream = Explorer.DataFrame.to_rows_stream(import.attachment_data)
      {:ok, stream}
    end
  end

  defp add_error(changeset, error) do
    Logger.warning("Error validating records: #{inspect(error)}")
    Changeset.add_error(changeset, error)
  end
end
