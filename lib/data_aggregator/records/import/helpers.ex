defmodule DataAggregator.Records.Import.Helpers do
  @moduledoc false

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  require Logger

  @type import_row_validation_result ::
          [import_row_validation_error()]

  @type import_row_validation_error :: %{
          catalog_number: String.t(),
          scientific_name: String.t(),
          field: atom(),
          value: String.t(),
          message: String.t()
        }

  @doc """
  Returns `true` if the row is valid and can be imported.
  """
  @spec valid_import_row?(Import.t(), map()) :: boolean()
  def valid_import_row?(%Import{} = import, row) do
    changeset = Record.changeset_to_import(import, row)

    changeset.valid?
  end

  @doc """
  Validates the row and returns the errors and the causing data in a list of maps, like:
      [
        %{
          catalog_number: row["mte_catalog_number"],
          scientific_name: row["tax_scientific_name"],
          field: :loc_decimal_longitude,
          value: "12,58683",
          message: "is invalid"
        }
      ]
  """
  @spec validate_import_row(Import.t(), map()) :: import_row_validation_result()
  def validate_import_row(%Import{} = import, row) do
    %Changeset{errors: errors} = Record.changeset_to_import(import, row)

    Enum.map(errors, fn error ->
      %{
        catalog_number: row["mte_catalog_number"],
        scientific_name: row["tax_scientific_name"],
        field: Map.get(error, :field),
        value: Map.get(error, :value),
        message: Exception.message(error)
      }
    end)
  end

  @doc """
  Opens a new error log file for the given import. and returns a
    tuple with the path and the file.
  """
  @spec open_error_log_file(Import.t()) :: {String.t(), any()}
  def open_error_log_file(import) do
    directory_path = FlatFileUtils.create_directory!("import_errors_#{import.id}")

    path = directory_path <> "/import_error_log-#{import.id}-#{Uniq.UUID.uuid7(:slug)}.csv"

    {path,
     File.open!(path, [
       :write,
       :utf8
     ])}
  end

  @doc """
  Writes the errors to a CSV file.
  """
  @spec write_error_log_file(any(), import_row_validation_result()) :: :ok
  def write_error_log_file(file, errors) do
    FlatFileUtils.store_local_file(file, errors,
      catalog_number: "catalogNumber",
      scientific_name: "scientificName",
      field: "field",
      value: "value",
      message: "message"
    )

    :ok
  end

  @doc """
  Uploads the error log file to S3 and updates the import with the attachment.
  """
  @spec upload_error_log_file!(String.t(), Import.t()) :: :ok
  def upload_error_log_file!(path, import) do
    import = Ash.load!(import, [:collection], lazy?: true)

    upload_fn = fn ->
      attachment = FlatFileUtils.store_on_s3!(path, import.collection)

      case Explorer.DataFrame.from_csv(path, infer_schema_length: 0) do
        {:ok, df} ->
          amount_of_errors = Explorer.DataFrame.n_rows(df)

          Logger.warning(
            "#{amount_of_errors} errors occured while importing. Adding errors as file to `import.error_log`"
          )

          import =
            import
            |> Import.update!(%{rows_error_count: amount_of_errors})
            |> Import.update_error_log!(attachment)

          # remove file from local tmp dir, as it is now stored on s3
          File.rm!(path)

          import

        {:error, _} ->
          Logger.debug("CSV could not be read or - more likely - it was empty, so no errors were found.")

          # delete error log, because it is not needed anymore
          Attachment.destroy!(attachment)

          # remove file from local tmp dir, as it is now stored on s3
          File.rm!(path)

          import
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
end
