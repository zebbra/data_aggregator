defmodule DataAggregator.Records.Approval.Helpers do
  @moduledoc """
  Helper functions for the `DataAggregator.Records.Approval` context.
  """

  alias Ash.Changeset

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
        records_count = Explorer.DataFrame.n_rows(df)

        Changeset.change_attribute(changeset, :records_count, records_count)

      {:error, error} ->
        Logger.warning("Approval CSV could not be read, error was #{inspect(error)}")

        Changeset.add_error(changeset, error)
    end
  end
end
