defmodule DataAggregator.Records.Collection.Workers.BatchRecordsEnqueuer do
  @moduledoc """
  `Oban.Worker` to enqueue batch encoding jobs for a collection.

  This worker streams records matching a query and creates `BatchEncoder` jobs
  for batches of record IDs, improving performance over the single-record approach.

  ## Arguments

  * `id` - the ID of the collection to enqueue encoding for
  * `query` - the AshPagify filter query for records to encode
  * `user_id` - the ID of the user to run the encoding as (optional)

  ## Batch Size

  The batch size is controlled by `Records.encode_job_batch_size()` (default: 100).
  Each batch becomes a single `BatchEncoder` Oban job.
  """

  use Oban.Worker, queue: :encoders, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.BatchEncoder

  require Ash.Query
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
    batch_size = Records.encode_job_batch_size()

    Logger.debug("Enqueueing batch encoding jobs for Collection #{collection.id}...")

    # Stream records, chunk into batches, create batch jobs
    {job_count, record_count} =
      Record
      |> AshPagify.query_for_filters_map(query)
      |> Ash.Query.set_tenant(collection)
      |> Ash.Query.select([:id])
      |> Ash.stream!(batch_size: 1000)
      |> Stream.map(& &1.id)
      |> Stream.chunk_every(batch_size)
      |> Enum.reduce({0, 0}, fn record_ids, {jobs, records} ->
        transition_to_queued(record_ids, collection)
        insert_batch_job(collection, record_ids, actor)
        {jobs + 1, records + length(record_ids)}
      end)

    Logger.debug("Enqueued #{job_count} batch encoding jobs for #{record_count} records in Collection #{collection.id}")

    :ok
  end

  defp transition_to_queued(record_ids, collection) do
    Record
    |> Ash.Query.filter(id in ^record_ids)
    |> Ash.Query.set_tenant(collection)
    |> Ash.bulk_update!(:set_queued, %{},
      tenant: collection,
      domain: Records,
      resource: Record,
      batch_size: Records.encode_db_batch_size()
    )
  end

  defp insert_batch_job(collection, record_ids, %User{id: user_id}) do
    %{
      record_ids: record_ids,
      collection_id: collection.id,
      user_id: user_id
    }
    |> BatchEncoder.new()
    |> Oban.insert!()
  end

  defp insert_batch_job(collection, record_ids, _) do
    %{
      record_ids: record_ids,
      collection_id: collection.id
    }
    |> BatchEncoder.new()
    |> Oban.insert!()
  end
end
