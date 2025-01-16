defmodule DataAggregator.Records.Record.Actions.EnqueueFastTrackChecker do
  @moduledoc """
  Enques the record to be processed by the `DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier` worker.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Publication.Scheduler
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, _ctx) do
    enqueue_fast_track_checker(input.arguments.published_record)
  end

  defp enqueue_fast_track_checker(record) do
    case insert_job(record) do
      {:ok, job} ->
        Logger.debug("Enqueued record fast_track_checker job #{inspect(job.id)}")
        {:ok, job}

      {:error, error} ->
        Logger.error("Failed to enqueue record fast_track_checker job: #{inspect(error)}")
        {:error, error}
    end
  end

  defp insert_job(%Record{id: id, collection_id: collection_id}) do
    %{id: id, collection_id: collection_id}
    |> Scheduler.FastTrackPublicationVerifier.new()
    |> Oban.insert()
  end

  defp insert_job(%PublishedRecord{record_id: id, collection_id: collection_id}) do
    %{id: id, collection_id: collection_id}
    |> Scheduler.FastTrackPublicationVerifier.new()
    |> Oban.insert()
  end
end
