defmodule DataAggregator.Records.Collection.Actions.StartValidations do
  @moduledoc """
  Custom action to start a validation process for a selection of records towards infospecies. It groups all records selected
  by a given query according to their infospecies center creates a ValidationRequest resource and calls the Collection.queue action for
  each group of records to send a DWC-Archive to the infospecies center.
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{actor: actor, tenant: tenant}) do
    collection =
      Ash.load!(input.arguments.collection, [:validation_query], lazy?: true, actor: actor)

    infospecies_centers = InfospeciesCenters.get_center_names()

    enqueued_centers =
      Enum.flat_map(infospecies_centers, fn center ->
        filter =
          Ash.Helpers.deep_merge_maps(
            collection.validation_query,
            ValidationRequest.Helpers.center_specific_filter(center)
          )

        query =
          Record
          |> Ash.Query.new()
          |> Ash.Query.filter_input(filter)

        # Use exists? instead of count to keep the synchronous LiveView path cheap.
        # The worker computes and sets total_rows_count as its first step.
        if Ash.exists?(query, tenant: tenant) do
          %{
            name: "vrq-#{collection.name}-#{:os.system_time()}",
            collection: collection,
            records_query: filter,
            center: center
          }
          |> ValidationRequest.create!(tenant: tenant)
          |> ValidationRequest.enqueue(%{started_by_id: actor.id},
            actor: actor,
            authorize?: false
          )

          [center]
        else
          []
        end
      end)

    {:ok, enqueued_centers}
  end
end
