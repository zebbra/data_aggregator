defmodule DataAggregator.Records.Record.Changes.EnqueueFastTrackChecker do
  @moduledoc """
  Enques the record to be processed by the `DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier` worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Publication.Scheduler
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue_fast_track_checker/1)
  end

  defp enqueue_fast_track_checker(%Changeset{data: record} = changeset) do
    case insert_job(record) do
      {:ok, job} ->
        Logger.debug("Enqueued record fast_track_checker job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue record fast_track_checker job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Record{id: id, collection_id: collection_id}) do
    %{id: id, collection_id: collection_id}
    |> Scheduler.FastTrackPublicationVerifier.new()
    |> Oban.insert()
  end
end
