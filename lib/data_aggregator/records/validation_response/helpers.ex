defmodule DataAggregator.Records.ValidationResponse.Helpers do
  @moduledoc """
  Helper functions for the `DataAggregator.Records.ValidationResponse` context.
  """

  alias Ash.Changeset
  alias Ash.Error.Changes.Required
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord

  require Logger

  @type validation_response_result ::
          [{map(), [Ash.Error.t()]}]

  @type validation_response_error :: %{
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
        Logger.warning("Validation CSV could not be read, error was #{inspect(error)}")

        Changeset.add_error(changeset, error)
    end
  end

  @doc """
  Creates a changeset, validates the data and returns the changeset
  """
  @spec valid_validation_row(map()) :: {boolean(), [Ash.Error.t()]}
  def valid_validation_row(row) do
    changeset = ValidatedRecord.changeset_to_validate(row)

    {changeset.valid?, changeset.errors}
  end

  @doc """
  Adds the raw record to each params map of the chunk
  """
  @spec add_raw_record_to_chunk({[map()], integer()}, Collection.t()) :: {[map()], integer()}
  def add_raw_record_to_chunk(chunk, tenant) do
    {rows, index} = chunk

    rows =
      Enum.map(rows, fn row ->
        case Record.get_by_mte_catalog_number(row.mte_catalog_number, tenant: tenant) do
          {:ok, record} ->
            row
            |> Map.put(:record, record)
            |> Map.put(:collection_id, record.collection_id)

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
  removes the collection attributes from the chunk
  The data we get from the CSV file may contain collection attributes, which we don't save on the record
  We need to remove them from the chunk before we save the records

  ## Example

      iex> chunk = {[%{"mte_catalog_number" => "123"}], 0}
      iex> collection_attributes = ["oth_collection_id"]
      iex> reject_collection_attributes_from_chunk(chunk, collection_attributes)
      {[%{"mte_catalog_number" => "123"}], 0}

      iex> chunk = {[%{"mte_catalog_number" => "123", "tax_scientific_name" => "foo", "oth_collection_id" => "bar"}], 0}
      iex> collection_attributes = ["oth_collection_id"]
      iex> reject_collection_attributes_from_chunk(chunk, collection_attributes)
      {[%{"mte_catalog_number" => "123", "tax_scientific_name" => "foo"}], 0}

      iex> chunk = {[%{"mte_catalog_number" => "123", "tax_scientific_name" => "foo", "oth_collection_id" => "bar"},%{"mte_catalog_number" => "123", "tax_scientific_name" => "foo", "oth_collection_id" => "bar"}], 0}
      iex> collection_attributes = ["oth_collection_id"]
      iex> reject_collection_attributes_from_chunk(chunk, collection_attributes)
      {[%{"mte_catalog_number" => "123", "tax_scientific_name" => "foo"},%{"mte_catalog_number" => "123", "tax_scientific_name" => "foo"}], 0}
  """
  @spec reject_collection_attributes_from_chunk(
          {[map()], integer()},
          [{atom(), String.t()}]
        ) :: {[map()], integer()}
  def reject_collection_attributes_from_chunk(chunk, collection_attributes) do
    {rows, index} = chunk

    rows =
      Enum.map(rows, fn row ->
        filter_collection_attributes(row, collection_attributes)
      end)

    {rows, index}
  end

  defp filter_collection_attributes(row, collection_attributes) do
    Enum.reduce(row, %{}, fn {dwc_field, value}, acc ->
      if dwc_field in collection_attributes do
        acc
      else
        Map.put(acc, dwc_field, value)
      end
    end)
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
  Opens a new error log file for the given validation resource and returns a
    tuple with the path and the file.
  """
  @spec open_error_log_file(ValidationResponse.t()) :: {String.t(), any()}
  def open_error_log_file(validation_response) do
    directory_path =
      FlatFileUtils.create_directory!("validation_response_errors_#{validation_response.id}")

    path =
      directory_path <>
        "/validation_response_error_log-#{validation_response.id}-#{Uniq.UUID.uuid7(:slug)}.csv"

    {path,
     File.open!(path, [
       :write,
       :utf8
     ])}
  end

  @doc """
  Writes the errors to a CSV file.
  """
  @spec write_error_log_file(any(), validation_response_result()) :: :ok
  def write_error_log_file(file, validation_response_result) do
    errors =
      validation_response_result
      |> Enum.map(fn {row, validation_response_errors} ->
        Enum.map(validation_response_errors, &map_to_normalized_error(&1, row))
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
  Uploads the error log file to S3 and updates the ValidationResponse with the attachment.
  """
  @spec upload_error_log_file!(String.t(), ValidationResponse.t()) :: ValidationResponse.t()
  def upload_error_log_file!(path, validation_response) do
    upload_fn = fn ->
      attachment = FlatFileUtils.store_on_s3!(path)

      case Explorer.DataFrame.from_csv(path) do
        {:ok, df} ->
          amount_of_errors = Explorer.DataFrame.n_rows(df)

          Logger.warning(
            "#{amount_of_errors} errors occured while validating. Adding errors as file to `ValidationResponse.error_log`"
          )

          validation_response =
            validation_response
            |> ValidationResponse.update!(%{rows_error_count: amount_of_errors})
            |> ValidationResponse.update_error_log!(attachment)

          # remove file from local tmp dir, as it is now stored on s3
          File.rm!(path)

          validation_response

        {:error, _} ->
          Logger.debug("CSV could not be read or - more likely - it was empty, so no errors were found.")

          validation_response
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

  @spec map_to_normalized_error(Ash.Error.t(), map()) :: validation_response_error()
  defp map_to_normalized_error(error, row) do
    case_result =
      case error do
        %Required{field: :record} ->
          %{
            field: :record,
            value: nil,
            message: "There is no record for the given catalog number in the database."
          }

        %Required{} = error ->
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
