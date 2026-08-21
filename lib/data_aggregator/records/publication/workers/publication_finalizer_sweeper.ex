defmodule DataAggregator.Records.Publication.Scheduler.PublicationFinalizerSweeper do
  @moduledoc """
  Safety net for records left behind in `:publishing`.

  `DataAggregator.Records.Publication.Scheduler.PublicationFinalizer` is what normally moves
  a record to `:published`. If that job is lost - discarded after its retries, cancelled by
  hand, dropped by a bad deploy - nothing else would ever move the record on and it would sit
  in `:publishing` forever.

  This worker runs hourly and finalizes any record that has been `:publishing` for longer than
  `DataAggregator.Records.publication_stranded_after/0`. Such a record was handed to GBIF
  successfully (the archive was built, uploaded and the endpoint created before the finalizer
  was ever enqueued), so `:published` is the honest outcome - only our bookkeeping failed.

  Records are tenant scoped per collection, so the sweep walks every collection.
  """
  use Oban.Worker, queue: :publication_finalizations, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @batch_size 1000

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    stranded_before =
      DateTime.add(DateTime.utc_now(), -Records.publication_stranded_after(), :millisecond)

    collections = Collection.read_all!(authorize?: false)

    count =
      Enum.reduce(collections, 0, fn collection, acc ->
        acc + sweep(collection, stranded_before)
      end)

    if count > 0 do
      Logger.warning("Finalized #{count} record(s) stranded in :publishing since before #{stranded_before}")
    end

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: to_timeout(hour: 1)

  defp sweep(collection, stranded_before) do
    result =
      Record
      |> Ash.Query.filter(
        publication_status == :publishing and updated_at < ^stranded_before and
          exists(published_record, publication.state == :done)
      )
      |> Ash.Query.set_tenant(collection.id)
      |> Ash.bulk_update(:update_publication_status, %{status: :published},
        authorize?: false,
        domain: Records,
        resource: Record,
        tenant: collection.id,
        return_records?: true,
        batch_size: @batch_size
      )

    case result do
      %Ash.BulkResult{status: :success, records: records} ->
        length(records || [])

      %Ash.BulkResult{errors: errors} ->
        # one bad collection must not stop the sweep of the others
        Logger.error("Failed to sweep stranded records of collection #{collection.id}: #{inspect(errors)}")

        0
    end
  end
end
