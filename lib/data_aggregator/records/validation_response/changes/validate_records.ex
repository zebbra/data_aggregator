defmodule DataAggregator.Records.ValidationResponse.Changes.ValidateRecords do
  @moduledoc """
  Changeset hook to validate records
  """

  use Ash.Resource.Change

  alias Ash.BulkResult
  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.Helpers
  alias DataAggregator.Records.ValidationResponse.NotificationHelpers

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &import_validation_data(&1), append?: true)
  end

  defp import_validation_data(%Changeset{} = changeset) do
    attachment_url = Changeset.get_attribute(changeset, :attachment_url)
    type = Changeset.get_attribute(changeset, :type)

    csv_content =
      attachment_url
      |> Helpers.fetch_file_from_url()
      |> Helpers.extract_csv_content()

    process(changeset, csv_content, type)
  end

  @spec process(Changeset.t(), String.t(), atom()) :: Changeset.t()
  defp process(changeset, csv_content, type) do
    with {:ok, df} <- Explorer.DataFrame.load_csv(csv_content),
         {:ok, stream} <- stream_from_dataframe(df),
         {:ok, stream} <- ensure_records(stream) do
      process_in_chunks(changeset, stream, type)
    else
      {:error, error} ->
        Logger.error("[Import validation records] CSV could not be read or it was empty")

        add_error(changeset, error)
    end
  end

  @spec process_in_chunks(Changeset.t(), Enum.t(), atom()) :: Changeset.t()
  defp process_in_chunks(%Changeset{} = changeset, rows, type) do
    chunk_size = Records.validation_response_batch_size()

    Logger.debug("Import validation rows in chunks of #{chunk_size} rows ...")

    collection_attributes = Helpers.get_collection_attributes(type)
    attribute_name_pairs = Helpers.get_header_attribute_name_pairs(type)

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&Helpers.add_raw_record_to_chunk/1)
    |> Stream.map(&Helpers.convert_headers_of_chunk(&1, attribute_name_pairs))
    |> Stream.map(&Helpers.reject_collection_attributes_from_chunk(&1, collection_attributes))
    |> Stream.map(&Helpers.maybe_convert_values(&1, type))
    |> Stream.map(&import_chunk(changeset, &1, type))
    |> reduce_validation_results(changeset)
    |> NotificationHelpers.notify_infospecies()
  end

  @spec import_chunk(Changeset.t(), {[map()], integer()}, atom()) ::
          {[BulkResult.t()], [map()], [{map(), [Ash.Error.t()]}]}
  defp import_chunk(%Changeset{data: validation_response}, {chunk, index}, type) do
    Logger.debug("Importing valid chunk ##{index} with #{length(chunk)} rows ...")

    max_concurrency = Records.import_max_concurrency()

    # will be in structure {[map()], [{map(), [Ash.Error.t()]}]}
    {valid, invalid} =
      chunk
      |> Task.async_stream(&{&1, Helpers.valid_validation_row(&1, type)},
        max_concurrency: max_concurrency,
        timeout: to_timeout(second: 30)
      )
      |> Enum.reduce({[], []}, fn
        {:ok, {row, {true, _errors}}}, {valid, invalid} -> {[row | valid], invalid}
        {:ok, {row, {false, errors}}}, {valid, invalid} -> {valid, [{row, errors} | invalid]}
      end)

    invalid_size = length(invalid)

    if invalid_size > 0 do
      Logger.warning("#{invalid_size} invalid row(s) dropped from chunk!")
    end

    Logger.debug("Importing #{length(valid)} rows ...")

    errors =
      valid
      |> Enum.reverse()
      |> Helpers.upsert_by_tenant!(type)

    Helpers.add_affected_collections(valid, validation_response)

    {errors, valid, invalid}
  end

  # For each chunk, we process the errors and update the changeset accordingly
  @spec reduce_validation_results(Enum.t(), Changeset.t()) :: Changeset.t()
  defp reduce_validation_results(results, %Changeset{data: validation_response} = changeset) do
    {path, error_log_file} = Helpers.open_error_log_file(validation_response)

    changeset =
      Enum.reduce_while(results, changeset, fn
        {errors, validated, invalid}, changeset ->
          changeset = report_progress(changeset, length(validated), length(invalid))

          Helpers.write_error_log_file(error_log_file, invalid)

          if Enum.empty?(errors) do
            # No errors, continue processing
            {:cont, changeset}
          else
            # There are errors, add them and halt, b'cause we do not want to let the
            # user wait until a erroneous import file is processed
            changeset = Enum.reduce(errors, changeset, &add_error(&2, &1))
            {:halt, changeset}
          end
      end)

    validation_response = Helpers.upload_error_log_file!(path, changeset.data)

    %{changeset | data: validation_response}
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
