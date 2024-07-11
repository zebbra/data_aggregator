defmodule DataAggregator.Records.Approval.Helpers do
  @moduledoc """
  Helper functions for the `DataAggregator.Records.Approval` context.
  """

  alias Ash.Changeset
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.ApprovedRecord
  alias DataAggregator.Records.Record

  require Logger

  @type approval_result ::
          [{map(), [Ash.Error.t()]}]

  @type approval_error :: %{
          catalog_number: String.t(),
          occurrence_id: String.t(),
          scientific_name: String.t(),
          field: atom(),
          value: String.t(),
          message: String.t()
        }

  @doc """
  Fetches a file from a given URL
  """
  @spec fetch_file_from_url(String.t()) :: String.t()
  def fetch_file_from_url(url) do
    %{body: dwca_file} = Req.get!(url)

    dwca_file
  end

  @doc """
  Extracts the content of the CSV file from the provided zip file
  """
  @spec extract_csv_content(binary()) :: binary()
  def extract_csv_content(dwca_zip_file) do
    {_file_name, csv_content} =
      Enum.find(dwca_zip_file, fn {file_name, _content} -> file_name == ~c"core.csv" end)

    csv_content
  end

  @doc """
  Counts the number of rows in the provided CSV blob and updates given changeset
  """
  @spec count_rows(Changeset.t(), binary()) :: Changeset.t()
  def count_rows(changeset, csv_content) do
    case Explorer.DataFrame.load_csv(csv_content) do
      {:ok, df} ->
        rows_count = Explorer.DataFrame.n_rows(df)

        Changeset.change_attribute(changeset, :rows_count, rows_count)

      {:error, error} ->
        Logger.warning("Approval CSV could not be read, error was #{inspect(error)}")

        Changeset.add_error(changeset, error)
    end
  end

  @doc """
  Creates a chanageset, validates the data and returns the changeset
  """
  @spec valid_approval_row(map()) :: {boolean(), [Ash.Error.t()]}
  def valid_approval_row(row) do
    changeset = ApprovedRecord.changeset_to_approve(row)

    {changeset.valid?, changeset.errors}
  end

  @doc """
  Adds the raw record to each params map of the chunk
  """
  @spec add_raw_record_to_chunk({[map()], integer()}) :: {[map()], integer()}
  def add_raw_record_to_chunk(chunk) do
    {rows, index} = chunk

    rows =
      Enum.map(rows, fn row ->
        case Record.get_by_mte_catalog_number(row.mte_catalog_number) do
          {:ok, record} ->
            Map.put(row, :record, record)

          {:error, _} ->
            row
        end
      end)

    {rows, index}
  end

  @doc """
  converts the headers of a chunk from dwc field names to our internal db field names
  """
  @spec convert_headers_of_chunk({[map()], integer()}, [{atom(), String.t()}]) ::
          {[map()], integer()}
  def convert_headers_of_chunk(chunk, attribute_pairs) do
    {rows, index} = chunk

    rows =
      Enum.map(rows, fn row ->
        Enum.reduce(row, %{}, fn {dwc_field, value}, acc ->
          db_attribute = get_attribute_from_pairs(attribute_pairs, dwc_field)

          Map.put(acc, db_attribute, value)
        end)
      end)

    {rows, index}
  end

  @doc """
  returns the internal db field name for a given dwc field name
  """
  @spec get_attribute_from_pairs([{atom(), String.t()}], String.t()) :: atom()
  def get_attribute_from_pairs(pairs, dwc_field) do
    {db_attribute, _dwc_field} = Enum.find(pairs, fn {_k, v} -> v == dwc_field end)

    db_attribute
  end

  @doc """
  Opens a new error log file for the given approval resource and returns a
    tuple with the path and the file.
  """
  @spec open_error_log_file(Approval.t()) :: {String.t(), any()}
  def open_error_log_file(approval) do
    directory_path = FlatFileUtils.create_directory!("approval_errors_#{approval.id}")

    path = directory_path <> "/approval_error_log-#{approval.id}-#{Uniq.UUID.uuid7(:slug)}.csv"

    {path,
     File.open!(path, [
       :write,
       :utf8
     ])}
  end

  @doc """
  Writes the errors to a CSV file.
  """
  @spec write_error_log_file(any(), approval_result()) :: :ok
  def write_error_log_file(file, approval_result) do
    errors =
      approval_result
      |> Enum.map(fn {row, approval_errors} ->
        Enum.map(approval_errors, &map_to_normalized_error(&1, row))
      end)
      |> List.flatten()

    FlatFileUtils.store_local_file(file, errors,
      catalog_number: "catalogNumber",
      scientific_name: "scientificName",
      occurrence_id: "occurrenceID",
      field: "field",
      value: "value",
      message: "message"
    )

    :ok
  end

  @doc """
  Uploads the error log file to S3 and updates the approval with the attachment.
  """
  @spec upload_error_log_file!(String.t(), Approval.t()) :: Approval.t()
  def upload_error_log_file!(path, approval) do
    upload_fn = fn ->
      attachment = FlatFileUtils.store_on_s3!(path)

      case Explorer.DataFrame.from_csv(path) do
        {:ok, df} ->
          amount_of_errors = Explorer.DataFrame.n_rows(df)

          Logger.warning(
            "#{amount_of_errors} errors occured while approving. Adding errors as file to `approval.error_log`"
          )

          approval =
            approval
            |> Approval.update!(%{rows_error_count: amount_of_errors})
            |> Approval.update_error_log!(attachment)

          # remove file from local tmp dir, as it is now stored on s3
          File.rm!(path)

          approval

        {:error, _} ->
          Logger.debug("CSV could not be read or - more likely - it was empty, so no errors were found.")

          approval
      end
    end

    if Records.execute_async?() do
      upload_fn
      |> Task.async()
      |> Task.await()
    else
      upload_fn.()
    end
  end

  @spec map_to_normalized_error(Ash.Error.t(), map()) :: approval_error()
  defp map_to_normalized_error(error, row) do
    case_result =
      case error do
        %Ash.Error.Changes.Required{field: :record} ->
          %{
            field: :record,
            value: nil,
            message: "There is no record for the given catalog number in the database."
          }

        %Ash.Error.Changes.Required{} = error ->
          %{
            field: Map.get(error, :field),
            value: nil,
            message: "Field is required but was empty."
          }

        %Ash.Error.Changes.InvalidAttribute{} = error ->
          %{
            field: Map.get(error, :field),
            value: Map.get(error, :value),
            message: Map.get(error, :message)
          }

        _ ->
          %{
            field: Map.get(error, :field) || "",
            value: Map.get(error, :value) || "",
            message: Map.get(error, :message) || "unknown error"
          }
      end

    Map.merge(case_result, %{
      catalog_number: row["mte_catalog_number"],
      scientific_name: row["tax_scientific_name"],
      occurrence_id: row["occ_occurrence_id"]
    })
  end
end
