defmodule DataAggregator.Records.Approval.Changes.ApproveRecords do
  @moduledoc """
  Changeset hook to approve records
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.Approval.Helpers

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &approve_records/1, append?: true)
  end

  defp approve_records(%Changeset{data: approval} = changeset) do
    file_url = Changeset.get_argument(changeset, :file_url)

    # download dwc-a zip file
    dwca_file = Helpers.fetch_file_from_url(file_url)

    # Find the file with the name "core.csv" from the zip file we downloaded before
    csv_content = Helpers.extract_csv_content(dwca_file)

    # TODO: go further here!!!!
    with {:ok, df} <- Explorer.DataFrame.load_csv(csv_content),
         {:ok, stream} <- get_df_as_stream(df),
         {:ok, _stream} <- ensure_records(stream) do
      # TODO: process the stream and import the approved records like it's done in import_records.ex
    else
      {:error, error} ->
        Logger.debug("CSV could not be read or it was empty")

        add_error(changeset, error, approval)
    end

    changeset
  end

  defp get_df_as_stream(df), do: {:ok, Explorer.DataFrame.to_rows_stream(df)}

  defp ensure_records(stream) do
    if Enum.empty?(stream) do
      {:error, "No records found in the CSV file"}
    else
      {:ok, stream}
    end
  end

  defp add_error(changeset, error, approval) do
    Logger.warning("Error while approving records: #{inspect(error)}")

    Approval.set_failed(approval)
    Changeset.add_error(changeset, error)
  end
end
