defmodule DataAggregator.Records.Publication.Scheduler.PublicationFinalizer do
  @moduledoc """
  Marks the records of a finished publication as `:published`.

  Publication is asserted, not verified: once the Darwin Core Archive has been handed to
  GBIF we give GBIF `DataAggregator.Records.publication_grace_period/0` to ingest it and
  then declare the records published. We do not ask the GBIF API whether the occurrences
  actually turned up - doing so cost one API call per record and hit GBIF's rate limit,
  which produced wrong states and error noise.

  See `docs/adr/0001-publication-is-asserted-not-verified.md`.

  ## Arguments

  * `publication_id` - the ID of the publication whose records should be finalized
  * `collection_id` - the ID of the collection the publication belongs to
  * `user_id` - the user who started the publication, credited with the status change

  """
  use Oban.Worker, queue: :publication_finalizations, max_attempts: 3

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @batch_size 1000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"publication_id" => publication_id, "collection_id" => collection_id} = args}) do
    Logger.debug("Finalizing publication #{publication_id} of collection #{collection_id}")

    count = finalize(publication_id, collection_id, actor(args["user_id"]))

    Logger.info("Finalized publication #{publication_id}: #{count} record(s) set to :published")

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: to_timeout(hour: 1)

  @doc """
  Builds the job that finalizes the given publication once the grace period has elapsed.

  Re-publishing the same publication reschedules the existing job rather than stacking a
  second one, so the grace period always runs from the most recent publication.
  """
  @spec new_job(String.t(), String.t(), String.t() | nil) :: Oban.Job.changeset()
  def new_job(publication_id, collection_id, user_id \\ nil) do
    new(
      %{publication_id: publication_id, collection_id: collection_id, user_id: user_id},
      unique: [
        period: :infinity,
        fields: [:args, :worker],
        keys: [:publication_id, :collection_id],
        states: :incomplete
      ],
      replace: [scheduled: [:scheduled_at]],
      schedule_in: {grace_period_in_seconds(), :second}
    )
  end

  # The finalization is a delayed consequence of the user's publish, so it is credited to them
  # rather than to the system.
  defp actor(nil), do: nil

  defp actor(user_id) do
    case User.get_by_id(user_id) do
      {:ok, user} -> user
      {:error, _} -> nil
    end
  end

  # Streams the records that went into this publication's archive and flips the ones that
  # are still `:publishing`. The filter is what makes this job idempotent and keeps it off
  # records that moved on to `:stale` or `:publication_failed` during the grace period.
  defp finalize(publication_id, collection_id, actor) do
    PublishedRecord
    |> Ash.Query.for_read(:by_publication, %{publication_id: publication_id},
      tenant: collection_id,
      authorize?: false
    )
    |> Ash.stream!(stream_with: :keyset, batch_size: @batch_size)
    |> Stream.map(& &1.record_id)
    |> Stream.chunk_every(@batch_size)
    |> Enum.reduce(0, fn record_ids, acc ->
      acc + finalize_batch(record_ids, collection_id, actor)
    end)
  end

  defp finalize_batch(record_ids, collection_id, actor) do
    result =
      Record
      |> Ash.Query.filter(id in ^record_ids and publication_status == :publishing)
      |> Ash.Query.set_tenant(collection_id)
      |> Ash.bulk_update(:update_publication_status, %{status: :published},
        actor: actor,
        authorize?: false,
        domain: Records,
        resource: Record,
        tenant: collection_id,
        return_records?: true,
        batch_size: @batch_size
      )

    case result do
      %Ash.BulkResult{status: :success, records: records} ->
        length(records || [])

      %Ash.BulkResult{errors: errors} ->
        raise "Failed to finalize records of collection #{collection_id}: #{inspect(errors)}"
    end
  end

  defp grace_period_in_seconds do
    Records.publication_grace_period()
    |> div(1000)
    |> max(0)
  end
end
