defmodule DataAggregator.Records.ValidationResponse.Helpers do
  @moduledoc """
  Helper functions for the `DataAggregator.Records.ValidationResponse` context.
  """

  alias Ash.Changeset
  alias Ash.Error.Changes.Required
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.ExtractAttributesHelpers
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
    case Enum.at(dwca_zip_file, 0) do
      nil -> nil
      {_file_name, csv_content} -> csv_content
    end
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
  Creates a changeset, validates the data to update the databese and returns the validitiy and/or errors
  """
  @spec valid_validation_row(map(), atom()) :: {boolean(), [Ash.Error.t()]}
  def valid_validation_row(row, :validated) do
    changeset = ValidatedRecord.changeset_to_validate(row)

    {changeset.valid?, changeset.errors}
  end

  def valid_validation_row(row, :not_validated) do
    case Map.get(row, :record) do
      nil ->
        {false, [%{message: "Record not found"}]}

      %Record{} ->
        {true, []}

      unknown ->
        message =
          "[Validation response import :not_validated] Error while looking for record on validation response import row: #{inspect(row)}, found: #{inspect(unknown)}"

        Logger.error(message)

        {false,
         [
           %{
             message: message
           }
         ]}
    end
  end

  @doc """
  Adds the raw record to each params map of the chunk
  """
  @spec add_raw_record_to_chunk({[map()], integer()}) :: {[map()], integer()}
  def add_raw_record_to_chunk({rows, index}) do
    rows =
      Enum.map(rows, fn row ->
        catalog_number = row["catalogNumber"]
        collection = collection_from_row(row)

        case Record.get_by_mte_catalog_number(catalog_number, tenant: collection) do
          {:ok, record} ->
            row |> Map.put(:record, record) |> Map.put(:collection_id, collection.id)

          {:error, error} ->
            Logger.error(error)

            row
        end
      end)

    {rows, index}
  end

  def get_collection_attributes(:not_validated) do
    ["collectionCode"]
  end

  def get_collection_attributes(:validated) do
    Enum.map(Schema.collection_attributes(), & &1.dwc_field)
  end

  @spec get_header_attribute_name_pairs(atom()) :: [{atom(), String.t()}]
  def get_header_attribute_name_pairs(:validated), do: Schema.prefixed_attribute_names_and_dwc_fields()

  def get_header_attribute_name_pairs(:not_validated),
    do: [{:code, "collectionCode"}, {:mte_catalog_number, "catalogNumber"}, {:validation_annotation, "annotation"}]

  # expects a map with record data and returns the extracted collection
  @spec collection_from_row(map()) :: Collection.t() | nil
  defp collection_from_row(row) do
    code = row["collectionCode"]

    case Collection.get_by_code(code) do
      {:ok, nil} ->
        nil

      {:ok, collection} ->
        collection

      {:error, _} ->
        Logger.error("Validation Response import: Error fetching collection for code: #{code}")

        nil
    end
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
  def reject_collection_attributes_from_chunk({rows, index}, collection_attributes) do
    rows =
      Enum.map(rows, fn row ->
        filter_collection_attributes(row, collection_attributes)
      end)

    {rows, index}
  end

  @spec maybe_convert_values({[map()], integer()}, atom()) :: {[map()], integer()}
  def maybe_convert_values({rows, index}, :validated) do
    rows =
      Enum.map(rows, fn row ->
        Map.new(row, fn {key, value} ->
          ExtractAttributesHelpers.maybe_convert_values({key, value})
        end)
      end)

    {rows, index}
  end

  def maybe_convert_values({rows, index}, :not_validated) do
    rows =
      Enum.map(rows, fn row ->
        %{row | validation_annotation: to_string(row.validation_annotation)}
      end)

    {rows, index}
  end

  @doc """
  returns the internal db field name for a given dwc field name or, if not found, the original field name
  """
  @spec get_attribute_from_pairs([{atom(), String.t()}], String.t()) :: atom()
  def get_attribute_from_pairs(pairs, dwc_field) do
    case Enum.find(pairs, fn {_k, v} -> v == dwc_field end) do
      nil -> dwc_field
      {db_attribute, _dwc_field} -> db_attribute
    end
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

  @doc """
  Groups rows according to identified tenants and updates records/upserts validated records
  """
  @spec upsert_by_tenant!(Enum.t(), atom()) :: Enum.t()
  def upsert_by_tenant!(rows, type)

  def upsert_by_tenant!(rows, :not_validated) do
    rows
    |> Enum.group_by(fn row -> get_tenant_from_row(row) end)
    |> Enum.filter(fn {tenant, _} -> tenant != nil end)
    |> Enum.map(&update_records/1)
    |> List.flatten()
  end

  def upsert_by_tenant!(rows, :validated) do
    rows
    |> Enum.group_by(fn row -> get_tenant_from_row(row) end)
    |> Enum.filter(fn {tenant, _} -> tenant != nil end)
    |> Enum.map(fn {tenant, rows} ->
      ValidatedRecord.bulk_validate!(rows, tenant: tenant)
    end)
    |> Enum.flat_map(fn %{errors: errors} -> errors end)
  end

  @doc """
  Add a collection which was affected by the import of rows of the given ValidationResponse struct
  """
  @spec add_affected_collections(Enum.t(), ValidationResponse.t()) :: :ok
  def add_affected_collections(valid, validation_response)

  def add_affected_collections(valid, validation_response) do
    Enum.each(valid, fn row ->
      record = Ash.load!(row.record, [:collection], lazy?: true)

      ValidationResponse.add_affected_collection!(validation_response, record.collection)
    end)

    :ok
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

  @spec update_records({Collection.t(), [map()]}) :: [map()]
  defp update_records({tenant, rows}) do
    Enum.reduce(rows, [], fn row, errors ->
      case Record.update(row.record, %{validation_annotation: row.validation_annotation}, tenant: tenant) do
        {:ok, _} -> errors
        {:error, error} -> errors ++ [error]
      end
    end)
  end

  @spec map_to_normalized_error(Ash.Error.t(), map()) :: validation_response_error()
  defp map_to_normalized_error(error, row) do
    known_error = check_for_known(error)

    Map.merge(known_error, %{
      catalog_number: row[:mte_catalog_number] || "",
      scientific_name: row[:tax_scientific_name] || "",
      occurrence_id: row[:occ_occurrence_id] || ""
    })
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

  defp check_for_known(error) do
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
  end
end
