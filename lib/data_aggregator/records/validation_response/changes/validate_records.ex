defmodule DataAggregator.Records.ValidationResponse.Changes.ValidateRecords do
  @moduledoc """
  Changeset hook to validate records
  """

  use Ash.Resource.Change

  alias Ash.BulkResult
  alias Ash.Changeset
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.Helpers
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &validate_records(&1), append?: true)
  end

  @spec validate_records(Changeset.t()) :: Changeset.t()
  defp validate_records(changeset) do
    file_url = Changeset.get_attribute(changeset, :file_url)

    validation_file = Helpers.fetch_file_from_url(file_url)
    csv_content = Helpers.extract_csv_content(validation_file)

    with {:ok, df} <- Explorer.DataFrame.load_csv(csv_content),
         {:ok, stream} <- stream_from_dataframe(df),
         {:ok, stream} <- ensure_records(stream) do
      validate_in_chunks(changeset, stream)
    else
      {:error, error} ->
        Logger.debug("CSV could not be read or it was empty")

        add_error(changeset, error)
    end
  end

  @spec validate_in_chunks(Changeset.t(), Enum.t()) :: Changeset.t()
  defp validate_in_chunks(%Changeset{} = changeset, rows) do
    chunk_size = Records.validation_response_batch_size()

    Logger.debug("Validating records in chunks of #{chunk_size} rows ...")

    collection_attributes = Enum.map(Schema.collection_attributes(), & &1.dwc_field)

    attribute_name_pairs =
      Schema.prefixed_attribute_names_and_dwc_fields()

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&Helpers.add_raw_record_to_chunk/1)
    |> Stream.map(&Helpers.convert_headers_of_chunk(&1, attribute_name_pairs))
    |> Stream.map(&Helpers.reject_collection_attributes_from_chunk(&1, collection_attributes))
    |> Stream.map(&Helpers.maybe_convert_values/1)
    |> Stream.map(&validate_chunk/1)
    |> reduce_validation_results(changeset)
    |> notify_infospecies()
  end

  @spec validate_chunk({[map()], integer()}) ::
          {[BulkResult.t()], [map()], [{map(), [Ash.Error.t()]}]}
  defp validate_chunk({chunk, index}) do
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

    results =
      valid
      |> Enum.reverse()
      |> validate_by_tenant!()

    {results, valid, invalid}
  end

  defp validate_by_tenant!(rows) do
    rows
    |> Enum.group_by(fn row -> get_tenant_from_row(row) end)
    |> Enum.filter(fn {tenant, _} -> tenant != nil end)
    |> Enum.map(fn {tenant, rows} ->
      ValidatedRecord.bulk_validate!(rows, tenant: tenant)
    end)
  end

  defp reduce_validation_results(results, %Changeset{data: validation_response} = changeset) do
    {path, error_log_file} = Helpers.open_error_log_file(validation_response)

    changeset =
      Enum.reduce_while(results, changeset, fn
        {bulk_results, validated, invalid}, changeset ->
          changeset = report_progress(changeset, length(validated), length(invalid))

          Helpers.write_error_log_file(error_log_file, invalid)

          # Collect all errors from all BulkResults
          all_errors = Enum.flat_map(bulk_results, fn %BulkResult{errors: errors} -> errors end)

          if Enum.empty?(all_errors) do
            # No errors, continue processing
            {:cont, changeset}
          else
            # There are errors, add them and halt, b'cause we do not want to let the
            # user wait until a erroneous import file is processed
            changeset = Enum.reduce(all_errors, changeset, &add_error(&2, &1))
            {:halt, changeset}
          end
      end)

    validation_response = Helpers.upload_error_log_file!(path, changeset.data)

    %{changeset | data: validation_response}
  end

  @spec notify_infospecies(Changeset.t()) :: Changeset.t()
  defp notify_infospecies(changeset) do
    with {:ok, response} <-
           RestAPI.notify_infospecies_with_validation_result(changeset.data),
         :ok <- ensure_status(response) do
      changeset
    else
      {:error, error} ->
        Logger.warning("Could not notify Infospecies about validation response result: #{inspect(error)}")

        # For now we just log the error and return the changeset without adding an error
        # add_error(changeset, error)
        changeset
    end
  end

  @spec get_tenant_from_row(map()) :: Collection.t() | nil
  defp get_tenant_from_row(_)

  defp get_tenant_from_row(%{collection: collection}) when collection != nil, do: collection

  defp get_tenant_from_row(%{collection_id: id}) when id != nil, do: Collection.get_by_id!(id)

  defp get_tenant_from_row(row) do
    Logger.error(
      "No tenant/collection found for validation in data: #{row}. Ensure that all rows have a valid collection."
    )

    nil
  end

  defp ensure_status(%{status: 200}), do: :ok

  defp ensure_status(response) do
    msg =
      "No valid response (status #{response.status}) from Infospecies API while notifying about processed validation response: #{inspect(response)}"

    {:error, msg}
  end

  @spec report_progress(Changeset.t(), non_neg_integer(), non_neg_integer()) :: Changeset.t()
  defp report_progress(changeset, validated, invalid) do
    Logger.debug("Batch successful (#{validated} validated, #{invalid} skipped)")

    %Changeset{data: validation_response} = changeset

    add_progress = fn ->
      ValidationResponse.add_validation_progress!(validation_response, validated, invalid)
    end

    validation_response =
      if Records.execute_async?() do
        add_progress |> Task.async() |> Task.await()
      else
        add_progress.()
      end

    %{changeset | data: validation_response}
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
