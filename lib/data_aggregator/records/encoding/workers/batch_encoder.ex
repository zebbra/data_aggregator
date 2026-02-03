defmodule DataAggregator.Records.Record.Workers.BatchEncoder do
  @moduledoc """
  `Oban.Worker` to perform bulk encoding of multiple records asynchronously.

  This worker processes a batch of records through all encoding catalogs using
  bulk database operations for improved performance.

  ## Arguments

  * `record_ids` - list of record IDs to encode
  * `collection_id` - the ID of the collection these records belong to
  * `user_id` - the ID of the user to run the encoding as (optional)

  ## Timeouts

  This worker uses `Records.encode_timeout() + 5 minutes` to allow for
  batch processing overhead.
  """

  use Oban.Worker, queue: :encoders, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Encoding.Actions.BulkEncodeRecords

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"record_ids" => record_ids, "collection_id" => collection_id, "user_id" => user_id}}) do
    with {:ok, collection} <- Collection.get_by_id(collection_id) do
      perform_with_actor(record_ids, collection, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"record_ids" => record_ids, "collection_id" => collection_id}}) do
    with {:ok, collection} <- Collection.get_by_id(collection_id) do
      perform_with_actor(record_ids, collection)
    end
  end

  defp perform_with_actor(record_ids, collection, actor \\ nil) do
    batch_size = length(record_ids)
    Logger.debug("Batch encoding #{batch_size} records for Collection #{collection.id}...")

    {:ok, results} =
      BulkEncodeRecords.run(record_ids, collection, actor: actor, tenant: collection)

    Logger.debug("Batch encoding completed: #{length(results.successful)} successful, #{length(results.failed)} failed")

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.encode_timeout() + to_timeout(minute: 5)
end
