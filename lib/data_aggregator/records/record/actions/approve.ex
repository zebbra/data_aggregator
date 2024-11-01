defmodule DataAggregator.Records.Actions.Approve do
  @moduledoc """
  Custom action to start an approval process for a selection of records towards infospecies. It groups all records selected
  by a given query according to their infospecies center creates a Publication resource and calls the Collection.publish action for
  each group of records to send a DWC-Archive to the infospecies center.
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{actor: actor, tenant: tenant}) do
    collection = input.arguments.collection
    query = input.arguments.query

    infospecies_centers = InfospeciesCenters.get_center_names()

    center_and_record_counts =
      Enum.map(infospecies_centers, fn center ->
        records_query =
          AshPagify.merge_filters(%AshPagify{filters: query}, %{
            encoded_record: %{swiss_species: %{center: %{eq: center}}}
          }).filters

        count_query = AshPagify.query_for_filters_map(Record, records_query)

        rows_count = Ash.count!(count_query)

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
          |> Publication.create!(tenant: tenant)
          |> Publication.enqueue(actor: actor, authorize?: false)
        end

        {center, rows_count}
      end)

    total_rows_count =
      Enum.reduce(center_and_record_counts, 0, fn {_, rows_count}, acc -> acc + rows_count end)

    # Mark the collection as approving only after all publications have been
    # created and enqueued and only if there are any publications. This has
    # the potential to introduce a duplicated approval for the same collection
    if total_rows_count > 0 do
      Collection.set_approving!(collection)
    end

    {:ok, center_and_record_counts}
  end
end
