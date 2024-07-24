defmodule DataAggregator.Records.Actions.Approve do
  @moduledoc """
  Custom action to start an approval process for a selection of records towards infospecies. It groups all records selected
  by a given query according to their infospecies center creates a Publication resource and calls the Collection.publish action for
  each group of records to send a DWC-Archive to the infospecies center.
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, _context) do
    collection = input.arguments.collection
    query = input.arguments.query

    infospecies_centers = InfospeciesCenters.get_center_names()

    center_and_record_counts =
      Enum.map(infospecies_centers, fn center ->
        records_query =
          Pagify.merge_filters(%Pagify{filters: query}, %{swiss_species: %{center: %{eq: center}}}).filters

        count_query = Pagify.query_for_filters_map(Record, records_query)

        rows_count = Records.count!(count_query)

        # do only publish dwc file to infospecies center if there are records
        if rows_count > 0 do
          %{
            name: "pub-#{collection.name}-#{:os.system_time()}",
            channel: :approval,
            records_query: records_query,
            collection: collection,
            rows_count: rows_count,
            center: center
          }
          |> Publication.create!()
          |> Publication.enqueue()
        end

        {center, rows_count}
      end)

    {:ok, center_and_record_counts}
  end
end
