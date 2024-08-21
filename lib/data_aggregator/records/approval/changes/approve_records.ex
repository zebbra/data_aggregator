defmodule DataAggregator.Records.Approval.Changes.ApproveRecords do
  @moduledoc """
  Changeset hook to approve records
  """

  use Ash.Resource.Change

  alias Ash.BulkResult
  alias Ash.Changeset
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.Approval.Helpers
  alias DataAggregator.Records.ApprovedRecord

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &approve_records/1, append?: true)
  end

  @spec approve_records(Changeset.t()) :: Changeset.t()
  defp approve_records(%Changeset{data: _approval} = changeset) do
    file_url = Changeset.get_attribute(changeset, :file_url)

    dwca_file = Helpers.fetch_file_from_url(file_url)

    csv_content = Helpers.extract_csv_content(dwca_file)

    with {:ok, df} <- Explorer.DataFrame.load_csv(csv_content),
         {:ok, stream} <- stream_from_dataframe(df),
         {:ok, stream} <- ensure_records(stream) do
      approve_in_chunks(changeset, stream)
    else
      {:error, error} ->
        Logger.debug("CSV could not be read or it was empty")

        add_error(changeset, error)
    end
  end

  @spec approve_in_chunks(Changeset.t(), Enum.t()) :: Changeset.t()
  defp approve_in_chunks(%Changeset{} = changeset, rows) do
    chunk_size = Records.approval_batch_size()

    Logger.debug("Approving records in chunks of #{chunk_size} rows ...")

    # the internal db field names and the dwc field names in tuples
    attribute_name_pairs = Schema.prefixed_attribute_names_and_dwc_fields()

    rows
    |> Stream.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Stream.map(&Helpers.convert_headers_of_chunk(&1, attribute_name_pairs))
    |> Stream.map(&Helpers.add_raw_record_to_chunk/1)
    |> Stream.map(&approve_chunk(&1))
    |> reduce_approval_results(changeset)
    |> notify_infospecies()
  end

  @spec approve_chunk({[map()], integer()}) ::
          {BulkResult.t(), [map()], [{map(), [Ash.Error.t()]}]}
  defp approve_chunk({chunk, index}) do
    Logger.debug("Approving chunk ##{index} with #{length(chunk)} rows ...")

    max_concurrency = Records.import_max_concurrency()

    # will be in structure {[map()], [{map(), [Ash.Error.t()]}]}
    {valid, invalid} =
      chunk
      |> Task.async_stream(&{&1, Helpers.valid_approval_row(&1)},
        max_concurrency: max_concurrency
      )
      |> Enum.reduce({[], []}, fn
        {:ok, {row, {true, _errors}}}, {valid, invalid} -> {[row | valid], invalid}
        {:ok, {row, {false, errors}}}, {valid, invalid} -> {valid, [{row, errors} | invalid]}
      end)

    if length(invalid) > 0 do
      Logger.warning("#{length(invalid)} invalid row(s) dropped from chunk!")
    end

    Logger.debug("Approving #{length(valid)} valid rows ...")

    res = ApprovedRecord.bulk_approve!(Enum.reverse(valid))

    {res, valid, invalid}
  end

  defp reduce_approval_results(results, %Changeset{data: approval} = changeset) do
    {path, error_log_file} = Helpers.open_error_log_file(approval)

    changeset =
      Enum.reduce_while(results, changeset, fn
        {%BulkResult{status: :success}, approved, invalid}, changeset ->
          changeset = report_progress(changeset, length(approved), length(invalid))

          Helpers.write_error_log_file(error_log_file, invalid)

          {:cont, changeset}

        {%BulkResult{errors: errors}, approved, invalid}, changeset ->
          changeset = report_progress(changeset, length(approved), length(invalid))

          changeset = Enum.reduce(errors, changeset, &add_error(&1, &2))
          {:halt, changeset}
      end)

    approval = Helpers.upload_error_log_file!(path, changeset.data)

    %{changeset | data: approval}
  end

  @spec notify_infospecies(Changeset.t()) :: Changeset.t()
  defp notify_infospecies(changeset) do
    with {:ok, response} <-
           RestAPI.notify_infospecies_with_approval_result(changeset.data),
         :ok <- ensure_status(response) do
      changeset
    else
      {:error, error} ->
        Logger.warning("Could not notify Infospecies about approval result: #{inspect(error)}")

        # For now we just log the error and return the changeset without adding an error
        # add_error(changeset, error)
        changeset
    end
  end

  defp ensure_status(%Req.Response{status: 200}), do: :ok

  defp ensure_status(response) do
    msg =
      "No valid response (status #{response.status}) from Infospecies API while notifying about processed approval: #{inspect(response.body)}"

    {:error, msg}
  end

  @spec report_progress(Changeset.t(), non_neg_integer(), non_neg_integer()) :: Changeset.t()
  defp report_progress(changeset, approved, invalid) do
    Logger.debug("Batch successful (#{approved} approved, #{invalid} skipped)")

    %Changeset{data: approval} = changeset

    add_progress = fn -> Approval.add_approval_progress!(approval, approved, invalid) end

    approval =
      if Records.execute_async?() do
        add_progress |> Task.async() |> Task.await()
      else
        add_progress.()
      end

    %{changeset | data: approval}
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
    Logger.warning("Error while approving records: #{inspect(error)}")

    Changeset.add_error(changeset, error)
  end
end
