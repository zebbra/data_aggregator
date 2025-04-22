defmodule DataAggregator.Records.Validation.Changes.ValidateRecords do
  @moduledoc """
  Changeset hook to validate records
  """

  use Ash.Resource.Change

  alias Ash.BulkResult
  alias Ash.Changeset
  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records
  alias DataAggregator.Records.ValidatedRecord
  alias DataAggregator.Records.Validation
  alias DataAggregator.Records.Validation.Helpers

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &validate_records(&1, ctx), append?: true)
  end

  @spec validate_records(Changeset.t(), Context.t()) :: Changeset.t()
  defp validate_records(changeset, ctx) do
    file_url = Changeset.get_attribute(changeset, :file_url)

    dwca_file = Helpers.fetch_file_from_url(file_url)

    csv_content = Helpers.extract_csv_content(dwca_file)

    with {:ok, df} <- Explorer.DataFrame.load_csv(csv_content),
         {:ok, stream} <- stream_from_dataframe(df),
         {:ok, stream} <- ensure_records(stream) do
      validate_in_chunks(changeset, stream, ctx)
    else
      {:error, error} ->
        Logger.debug("CSV could not be read or it was empty")

        add_error(changeset, error)
    end
  end

  @spec validate_in_chunks(Changeset.t(), Enum.t(), Context.t()) :: Changeset.t()
  defp validate_in_chunks(%Changeset{} = changeset, rows, %{tenant: tenant} = ctx) do
    chunk_size = Records.validation_batch_size()

    Logger.debug("Validating records in chunks of #{chunk_size} rows ...")

    collection_attributes = Enum.map(Schema.collection_attributes(), & &1.dwc_field)

    attribute_name_pairs =
      Schema.prefixed_attribute_names_and_dwc_fields()

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&Helpers.reject_collection_attributes_from_chunk(&1, collection_attributes))
    |> Stream.map(&Helpers.convert_headers_of_chunk(&1, attribute_name_pairs))
    |> Stream.map(&Helpers.add_raw_record_to_chunk(&1, tenant))
    |> Stream.map(&validate_chunk(&1, ctx))
    |> reduce_validation_results(changeset)
    |> notify_infospecies()
  end

  @spec validate_chunk({[map()], integer()}, Context.t()) ::
          {BulkResult.t(), [map()], [{map(), [Ash.Error.t()]}]}
  defp validate_chunk({chunk, index}, %{tenant: tenant}) do
    Logger.debug("Validating chunk ##{index} with #{length(chunk)} rows ...")

    max_concurrency = Records.import_max_concurrency()

    # will be in structure {[map()], [{map(), [Ash.Error.t()]}]}
    {valid, invalid} =
      chunk
      |> Task.async_stream(&{&1, Helpers.valid_validation_row(&1)},
        max_concurrency: max_concurrency,
        timeout: to_timeout(second: 30)
      )
      |> Enum.reduce({[], []}, fn
        {:ok, {row, {true, _errors}}}, {valid, invalid} -> {[row | valid], invalid}
        {:ok, {row, {false, errors}}}, {valid, invalid} -> {valid, [{row, errors} | invalid]}
      end)

    if length(invalid) > 0 do
      Logger.warning("#{length(invalid)} invalid row(s) dropped from chunk!")
    end

    Logger.debug("Validating #{length(valid)} valid rows ...")

    res = ValidatedRecord.bulk_validate!(Enum.reverse(valid), tenant: tenant)

    {res, valid, invalid}
  end

  defp reduce_validation_results(results, %Changeset{data: validation} = changeset) do
    {path, error_log_file} = Helpers.open_error_log_file(validation)

    changeset =
      Enum.reduce_while(results, changeset, fn
        {%BulkResult{status: :success}, validated, invalid}, changeset ->
          changeset = report_progress(changeset, length(validated), length(invalid))

          Helpers.write_error_log_file(error_log_file, invalid)

          {:cont, changeset}

        {%BulkResult{errors: errors}, validated, invalid}, changeset ->
          changeset = report_progress(changeset, length(validated), length(invalid))

          changeset = Enum.reduce(errors, changeset, &add_error(&1, &2))
          {:halt, changeset}
      end)

    validation = Helpers.upload_error_log_file!(path, changeset.data)

    %{changeset | data: validation}
  end

  @spec notify_infospecies(Changeset.t()) :: Changeset.t()
  defp notify_infospecies(changeset) do
    with {:ok, response} <-
           RestAPI.notify_infospecies_with_validation_result(changeset.data),
         :ok <- ensure_status(response) do
      changeset
    else
      {:error, error} ->
        Logger.warning("Could not notify Infospecies about validation result: #{inspect(error)}")

        # For now we just log the error and return the changeset without adding an error
        # add_error(changeset, error)
        changeset
    end
  end

  defp ensure_status(%Req.Response{status: 200}), do: :ok

  defp ensure_status(response) do
    msg =
      "No valid response (status #{response.status}) from Infospecies API while notifying about processed validation: #{inspect(response.body)}"

    {:error, msg}
  end

  @spec report_progress(Changeset.t(), non_neg_integer(), non_neg_integer()) :: Changeset.t()
  defp report_progress(changeset, validated, invalid) do
    Logger.debug("Batch successful (#{validated} validated, #{invalid} skipped)")

    %Changeset{data: validation} = changeset

    add_progress = fn -> Validation.add_validation_progress!(validation, validated, invalid) end

    validation =
      if Records.execute_async?() do
        add_progress |> Task.async() |> Task.await()
      else
        add_progress.()
      end

    %{changeset | data: validation}
  end

  defp stream_from_dataframe(df), do: {:ok, Explorer.DataFrame.to_rows_stream(df)}

  @spec ensure_records(Enum.t()) :: {:ok, Enum.t()} | {:error, String.t()}
  defp ensure_records(stream) do
    if Enum.empty?(stream) do
      {:error, "No records found in the CSV file"}
    else
      {:ok, stream}
    end
  end

  @spec add_error(Changeset.t(), Ash.Error.t() | String.t()) :: Changeset.t()
  defp add_error(changeset, error) do
    Logger.warning("Error while validating records: #{inspect(error)}")

    Changeset.add_error(changeset, error)
  end
end
