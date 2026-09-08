defmodule DataAggregator.Records.Collection.Workers.EncodingStatePoller do
  @moduledoc """
  `Oban.Worker` that polls a collection's encoding state.

  Each tick is a one-shot job (`max_attempts: 1`). While the collection is
  still encoding, the worker schedules the next tick and returns. The
  interval starts at #{5}s and doubles each tick up to a cap of #{60}s, so
  the cadence is 5s → 10s → 20s → 40s → 60s → 60s → … When the collection
  finishes encoding (or transitions to any non-`:encoding` state) the worker
  calls `Collection.set_idle_encoding/1` and stops scheduling.

  A unique constraint keyed on `args.id` limits this to one pending poller
  per collection at a time, while leaving other collections free to poll
  concurrently. The current interval lives in args but is excluded from the
  unique key so it can grow without splitting jobs.

  The constraint only applies to the *first* tick (`start/1`). Follow-up ticks
  are inserted with `unique: false`, because a tick schedules its successor
  while it is itself still `:executing` - a state included in `:incomplete` -
  so a unique insert would conflict with the very job doing the inserting and
  be silently dropped, halting the chain after one tick. Uniqueness is not
  needed there: a chain is serial, so only the single executing tick ever
  inserts the next one.

  If a tick raises, the job is discarded and polling halts for that
  collection. This is intentional — the previous snooze-based implementation
  silently retried with growing exponential backoff and masked real errors.
  Re-run `Collection.enqueue_encoding/2` to recover.

  ## Arguments

  * `id` - the ID of the collection to poll
  * `interval` - the interval (in seconds) used to schedule this tick;
    populated by `schedule_next/2`
  """
  use Oban.Worker,
    queue: :encoders,
    max_attempts: 1,
    unique: [
      period: :infinity,
      fields: [:worker, :args],
      keys: [:id],
      states: :incomplete
    ]

  import Ash.Expr

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @min_interval 5
  @max_interval 120

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = args}) do
    collection = Collection.get_by_id!(id)
    current_interval = Map.get(args, "interval", @min_interval)

    case encoding_state(collection) do
      :encoding ->
        next_interval = min(@max_interval, current_interval * 2)

        Logger.debug("Collection #{id} still encoding, scheduling next poll in #{next_interval}s")

        schedule_next(id, next_interval)
        :ok

      other ->
        Logger.info("Collection #{id} done encoding (#{other}), setting to idle ...")
        Collection.set_idle_encoding(collection)
    end
  end

  @doc """
  Inserts the first polling tick for the given collection, in #{@min_interval}s.

  Guarded by the worker's unique constraint, so re-triggering an encoding while
  a poller chain is already running for the collection is a no-op.
  """
  def start(id), do: insert_tick(id, @min_interval, [])

  @doc """
  Inserts the follow-up polling tick for the given collection in `interval` seconds.

  Called from `perform/1` only. Bypasses the unique constraint - see the module
  documentation for why.
  """
  def schedule_next(id, interval \\ @min_interval) do
    insert_tick(id, interval, unique: false)
  end

  defp insert_tick(id, interval, opts) do
    %{id: id, collection_id: id, interval: interval}
    |> new([schedule_in: interval] ++ opts)
    |> Oban.insert!()
  end

  defp encoding_state(collection) do
    count_encoded = records_count_encoded(collection)

    cond do
      count_encoded == collection.records_count ->
        :encoded

      records_count_queued_or_encoding(collection) > 0 ->
        :encoding

      records_count_failed(collection) > 0 ->
        :failed

      collection.records_count > count_encoded ->
        :incomplete

      true ->
        :unknown
    end
  end

  defp records_count_encoded(collection) do
    Record
    |> Ash.Query.set_tenant(collection)
    |> Ash.Query.filter(expr(state == :encoded))
    |> Ash.count!()
  end

  defp records_count_queued_or_encoding(collection) do
    Record
    |> Ash.Query.set_tenant(collection)
    |> Ash.Query.filter(expr(state in [:queued, :encoding]))
    |> Ash.count!()
  end

  defp records_count_failed(collection) do
    Record
    |> Ash.Query.set_tenant(collection)
    |> Ash.Query.filter(expr(state == :failed))
    |> Ash.count!()
  end
end
