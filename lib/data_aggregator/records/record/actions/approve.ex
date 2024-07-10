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

    Logger.error("infospecies_centers #{inspect(infospecies_centers)}")

    center_and_record_counts =
      Enum.map(infospecies_centers, fn center ->
        center_query = Map.put(query, :swiss_species, %{center: %{eq: center}})
        ash_query = get_ash_query(center_query)

        count = Records.count!(ash_query)

        Logger.error("center: #{center}, count: #{count}")

        # do only publish dwc file to infospecies center if there are records
        if count > 0 do
          %{
            name: "pub-#{collection.name}-#{:os.system_time()}",
            channel: :approval,
            records_query: center_query,
            collection: collection,
            rows_count: Records.count!(ash_query),
            center: center
          }
          |> Publication.create!()
          |> Publication.enqueue()
        end

        {center, count}
      end)

    Logger.error("centers and their record counts: #{inspect(center_and_record_counts)}")

    {:ok, center_and_record_counts}
  end

  def get_ash_query(query), do: Ash.Query.filter_input(Record, query)
end
