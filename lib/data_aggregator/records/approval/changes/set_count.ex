defmodule DataAggregator.Records.Approval.Changes.SetCount do
  @moduledoc """
  Sets the records_count of the approval object according to the rows count in the provided file
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Approval.Helpers

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    file_url = Changeset.get_attribute(changeset, :file_url)

    if file_url != nil do
      # download dwc-a zip file
      dwca_file = Helpers.fetch_file_from_url(file_url)

      # Find the file with the name "core.csv" from the zip file we downloaded before
      csv_content = Helpers.extract_csv_content(dwca_file)

      # count the number of rows in the csv file and return the modified changeset
      Helpers.count_rows(changeset, csv_content)
    else
      Changeset.add_error(changeset, ":file_url is required")
    end
  end
end
