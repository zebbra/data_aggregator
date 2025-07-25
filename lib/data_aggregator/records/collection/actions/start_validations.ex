defmodule DataAggregator.Records.Collection.Actions.StartValidations do
  @moduledoc """
  Custom action to start an validation process for a selection of records towards infospecies. It groups all records selected
  by a given query according to their infospecies center creates a ValidationRequest resource and calls the Collection.validate action for
  each group of records to send a DWC-Archive to the infospecies center.
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
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

        count_query =
          Record
          |> AshPagify.query_for_filters_map(records_query)
          |> Ash.Query.set_tenant(tenant)

        rows_count = Ash.count!(count_query)

        # do only create a validation request if there are records
        if rows_count > 0 do
          %{
            name: "vrq-#{collection.name}-#{:os.system_time()}",
            records_query: records_query,
            collection: collection,
            total_rows_count: rows_count,
            center: center
          }
          |> ValidationRequest.create!(tenant: tenant)
          |> ValidationRequest.enqueue(%{started_by_id: actor.id},
            actor: actor,
            authorize?: false
          )
        end

        {center, rows_count}
      end)

    total_rows_count =
      Enum.reduce(center_and_record_counts, 0, fn {_, rows_count}, acc -> acc + rows_count end)

    # Mark the collection as validating only after all validation requests have been
    # created and enqueued and only if there are any validation requests. This has
    # the potential to introduce a duplicated validation for the same collection
    if total_rows_count > 0 do
      Collection.set_validating!(collection)
    end

    {:ok, center_and_record_counts}
  end
end
