defmodule DataAggregator.Records.Approval.Changes.ApproveRecords do
  @moduledoc """
  Changeset hook to approve records
  """

  use Ash.Resource.Change

  alias Ash.BulkResult
  alias Ash.Changeset
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.Approval.Helpers
  alias DataAggregator.Records.ApprovedRecord

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &approve_records/1, append?: true)
  end

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

    changeset
  end

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

  def reduce_approval_results(results, changeset) do
    Enum.reduce_while(results, changeset, fn
      {%BulkResult{status: :success}, approved, invalid}, changeset ->
        changeset = report_progress(changeset, length(approved), length(invalid))
        {:cont, changeset}

      {%BulkResult{errors: errors}, approved, invalid}, changeset ->
        changeset = report_progress(changeset, length(approved), length(invalid))

        # TODO: extract errors from results --> looks like: {%BulkResult{status: :success}, {approved_rows, errors}, {invalid_rows, errors}}, write to error log file and upload it as in validate_rows.ex done

        changeset = Enum.reduce(errors, changeset, &add_error(&1, &2))
        {:halt, changeset}
    end)
  end

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

  defp ensure_records(stream) do
    if Enum.empty?(stream) do
      {:error, "No records found in the CSV file"}
    else
      {:ok, stream}
    end
  end

  defp add_error(changeset, error) do
    Logger.warning("Error while approving records: #{inspect(error)}")

    Changeset.add_error(changeset, error)
  end
end
