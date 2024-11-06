defmodule DataAggregator.Records.Collection.Workers.EncodingStatePoller do
  @moduledoc """
  `Oban.Worker` to verify if a collection is still in state encoding (runs every 5 seconds until done).

  ```elixir
  %{id: collection.id}
    |> Collection.Workers.EncodingStatePoller.new()
    |> Oban.insert()
  ```

  ## Arguments

  * `id` - the ID of the collection to poll

  ## Timeouts

  This worker uses the timeout

  """
  use Oban.Worker, queue: :encoders, max_attempts: 1

  import Ash.Expr

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @impl Worker
  def backoff(%Job{} = job) do
    # snooze increases the attempt by 1, so we need to correct it
    corrected_attempt = 1 - (job.max_attempts - job.attempt)

    Worker.backoff(%{job | attempt: corrected_attempt})
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}, attempt: attempt}) do
    Logger.info("Polling encoding state for collection #{id} (attempt #{attempt}) ...")

    # give it a bit of time to start encoding
    if attempt == 1, do: :timer.sleep(:timer.seconds(1))

    collection = Collection.get_by_id!(id)
    state = encoding_state(collection)

    if state == :encoding do
      Logger.info("Collection #{id} is still encoding, snoozing for 5 seconds...")
      {:snooze, 5}
    else
      Logger.info("Collection #{id} is done encoding (#{state}), setting to idle ...")
      Collection.set_idle_encoding(collection)
    end
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
