defmodule DataAggregator.Records.Approval.Helpers do
  @moduledoc """
  Helper functions for the `DataAggregator.Records.Approval` context.
  """

  alias Ash.Changeset
  alias DataAggregator.Records.ApprovedRecord
  alias DataAggregator.Records.Record

  require Logger

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
end
