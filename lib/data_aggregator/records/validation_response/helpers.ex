defmodule DataAggregator.Records.ValidationResponse.Helpers do
  @moduledoc """
  Helper functions for the `DataAggregator.Records.ValidationResponse` context.
  """

  alias Ash.Error.Changes.Required
  alias DataAggregator.Accounts.User
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.ExtractAttributesHelpers
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord

  require Logger

  # Terms no longer part of the validation request, so they must not reach the
  # validation layer even if a center still returns them.
  @denied_headers ["county"]

  # Prefix the validation request file uses for the columns of the encoding layer.
  @encoded_header_prefix "encoded "

  # Written once when the log file is opened; every write then appends value-only rows,
  # so the log keeps a single header row no matter how many chunks contribute errors.
  @error_log_headers [
    {:catalog_number, "catalogNumber"},
    {:scientific_name, "scientificName"},
    {:occurrence_id, "occurrenceID"},
    {:field, "field"},
    {:value, "value"},
    {:message, "message"}
  ]

  @type validation_response_result ::
          [{map(), [Ash.Error.t()]}]

  @type validation_response_error :: %{
          catalog_number: String.t(),
          occurrence_id: String.t(),
          scientific_name: String.t(),
          field: atom() | String.t(),
          value: String.t(),
          message: String.t()
        }

  @doc """
  Fetches a file from a given URL
  """
  @spec fetch_file_from_url(String.t()) :: String.t()
  def fetch_file_from_url(url) do
    %{body: dwca_file} = Req.get!(url, decoders: [:zip])

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
  Creates a changeset, validates the data to update the databese and returns the validitiy and/or errors
  """
  @spec valid_validation_row(map(), atom()) :: {boolean(), [Ash.Error.t()]}
  def valid_validation_row(%{record: %Record{}} = row, :validated) do
    changeset = ValidatedRecord.changeset_to_validate(row)
    {changeset.valid?, changeset.errors}
  end

  def valid_validation_row(%{record: %Record{}}, :not_validated) do
    {true, []}
  end

  def valid_validation_row(%{record: record} = row, type) when not is_nil(record) do
    message =
      "[Validation response import :#{to_string(type)}] Error while looking for record on validation response import row: #{inspect(row)}, found: #{inspect(record)}"

    Logger.error(message)

    {false,
     [
       %{
         message: message
       }
     ]}
  end

  def valid_validation_row(_row, _type) do
    {false, [%{message: "Record not found for given catalogNumber and collectionCode"}]}
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

  @doc """
  The CSV headers of a validation response that are not ingested.

  Dropping them early matters: an unknown header reaches the changeset as a plain string
  key and fails every single row with `NoSuchInput`.
  """
  @spec ignored_headers([String.t()], atom()) :: [String.t()]
  def ignored_headers(headers, type) do
    known_headers = known_headers(type)

    Enum.reject(headers, &MapSet.member?(known_headers, &1))
  end

  @spec known_headers(atom()) :: MapSet.t(String.t())
  defp known_headers(type) do
    type
    |> get_header_attribute_name_pairs()
    |> Enum.map(fn {_attribute, dwc_field} -> dwc_field end)
    |> Enum.concat(get_collection_attributes(type))
    |> Enum.reject(&(&1 in @denied_headers))
    |> MapSet.new()
  end

  @doc """
  Removes the ignored headers from every row of the chunk.
  """
  @spec reject_ignored_headers_from_chunk({[map()], integer()}, [String.t()]) ::
          {[map()], integer()}
  def reject_ignored_headers_from_chunk(chunk, []), do: chunk

  def reject_ignored_headers_from_chunk({rows, index}, ignored_headers) do
    ignored_headers = MapSet.new(ignored_headers)

    rows =
      Enum.map(
        rows,
        &Map.reject(&1, fn {header, _value} -> MapSet.member?(ignored_headers, header) end)
      )

    {rows, index}
  end

  @doc """
  Builds the error log entries describing which CSV columns were ignored. The `encoded `
  columns are reported as a single entry, as a full request file carries one per term.
  """
  @spec ignored_header_errors([String.t()]) :: [validation_response_error()]
  def ignored_header_errors([]), do: []

  def ignored_header_errors(ignored_headers) do
    {encoded_headers, other_headers} =
      Enum.split_with(ignored_headers, &String.starts_with?(&1, @encoded_header_prefix))

    encoded_errors =
      if encoded_headers == [] do
        []
      else
        [
          ignored_header_error(
            "#{@encoded_header_prefix}*",
            "#{length(encoded_headers)} column(s) of the encoding layer were ignored, only the raw values are ingested."
          )
        ]
      end

    encoded_errors ++
      Enum.map(
        other_headers,
        &ignored_header_error(&1, "Column is not part of the validation and was ignored.")
      )
  end

  @spec ignored_header_error(String.t(), String.t()) :: validation_response_error()
  defp ignored_header_error(header, message) do
    %{
      catalog_number: "",
      scientific_name: "",
      occurrence_id: "",
      field: header,
      value: "",
      message: message
    }
  end

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
        row
        |> Enum.map(fn {key, value} ->
          ExtractAttributesHelpers.maybe_convert_values({key, value})
        end)
        |> List.flatten()
        |> Map.new()
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

    file = File.open!(path, [:write, :utf8])

    FlatFileUtils.store_on_disk!(
      [Enum.map(@error_log_headers, fn {_key, header} -> header end)],
      file,
      false
    )

    {path, file}
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

    write_normalized_errors(file, errors)
  end

  @doc """
  Writes already normalized errors or notices to the error log CSV file.
  """
  @spec write_normalized_errors(any(), [validation_response_error()]) :: :ok
  def write_normalized_errors(_file, []), do: :ok

  def write_normalized_errors(file, errors) do
    rows =
      Enum.map(errors, fn error ->
        Enum.map(@error_log_headers, fn {key, _} -> Map.get(error, key) end)
      end)

    FlatFileUtils.store_on_disk!(rows, file, false)

    :ok
  end

  @doc """
  Uploads the error log file to S3 and updates the ValidationResponse with the attachment.
  """
  @spec upload_error_log_file!(String.t(), ValidationResponse.t(), non_neg_integer()) ::
          ValidationResponse.t()
  def upload_error_log_file!(path, validation_response, notice_count) do
    upload_fn = fn ->
      case Explorer.DataFrame.from_csv(path, infer_schema_length: 0) do
        {:ok, df} ->
          maybe_attach_error_log!(
            path,
            validation_response,
            Explorer.DataFrame.n_rows(df),
            notice_count
          )

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

  # Nothing but the header row: no errors, no notices, so there is nothing worth attaching.
  @spec maybe_attach_error_log!(
          String.t(),
          ValidationResponse.t(),
          non_neg_integer(),
          non_neg_integer()
        ) ::
          ValidationResponse.t()
  defp maybe_attach_error_log!(path, validation_response, 0, _notice_count) do
    Logger.debug("No errors were found while validating, so no error log is attached.")

    File.rm!(path)

    validation_response
  end

  defp maybe_attach_error_log!(path, validation_response, row_count, notice_count) do
    attachment = FlatFileUtils.store_on_s3!(path, nil)

    # notices (e.g. ignored columns) share the log file but are not row errors
    amount_of_errors = max(row_count - notice_count, 0)

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
  end

  @doc """
  Groups rows according to identified tenants and updates records/upserts validated records
  """
  @spec upsert_by_tenant!(Enum.t(), atom(), User.t()) :: Enum.t()
  def upsert_by_tenant!(rows, type, actor)

  def upsert_by_tenant!(rows, :not_validated, actor) do
    rows
    |> Enum.group_by(fn row -> get_tenant_from_row(row) end)
    |> Enum.filter(fn {tenant, _} -> tenant != nil end)
    |> Enum.map(&update_records(&1, actor))
    |> List.flatten()
  end

  def upsert_by_tenant!(rows, :validated, actor) do
    rows
    |> Enum.group_by(fn row -> get_tenant_from_row(row) end)
    |> Enum.filter(fn {tenant, _} -> tenant != nil end)
    |> Enum.map(fn {tenant, rows} ->
      ValidatedRecord.bulk_validate!(rows, tenant: tenant, actor: actor)
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

  @spec update_records({Collection.t(), [map()]}, User.t()) :: [map()]
  defp update_records({tenant, rows}, actor) do
    Enum.reduce(rows, [], fn row, errors ->
      case Record.set_validation_status_not_validated(
             row.record,
             row.validation_annotation,
             %{},
             %{
               actor: actor,
               tenant: tenant
             }
           ) do
        {:ok, _record} ->
          errors

        {:error, error} ->
          errors ++ [error]
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

      %Ash.Error.Invalid.NoSuchInput{} = error ->
        %{
          field: Map.get(error, :input),
          value: nil,
          message: "There is no such input field."
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
