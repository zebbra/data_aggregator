defmodule DataAggregator.Records.Collection.Workers.RecordsEnqueuer do
  @moduledoc """
  `Oban.Worker` to perform `DataAggregator.Records.Collection.enqueue_encoding/2` asynchronously.

  Usually this is not used directly, but rather through `DataAggregator.Records.Collection.enqueue_encoding/2`:

  ```elixir
  {:ok, collection} =
    collection_id
    |> DataAggregator.Records.Collection.get_by_id!()
    |> DataAggregator.Records.Collection.enqueue_encoding(records_to_enqueue_query)
  ```

  ## Arguments

  * `id` - the ID of the collection to enqueue during the run
  * `query` - the query to use to filter the records to enqueue

  ## Timeouts

  This worker does not use timeouts
  """

  use Oban.Worker, queue: :encoders, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "query" => query, "user_id" => user_id}}) do
    with {:ok, collection} <- Collection.get_by_id(id) do
      perform_with_actor(collection, query, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "query" => query}}) do
    with {:ok, collection} <- Collection.get_by_id(id) do
      perform_with_actor(collection, query)
    end
  end

  defp perform_with_actor(collection, query, actor \\ nil) do
    Logger.debug("Enqueuing records for Collection #{collection.id} in progress...")

    Record
    |> AshPagify.query_for_filters_map(query)
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!()
    |> Enum.each(&Record.enqueue_encoder!(&1, actor: actor, authorize?: false))
  end
end
