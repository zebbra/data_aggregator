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
    enqueue_fast_track_checker(changeset)
  end

  defp enqueue_fast_track_checker(%Changeset{data: record} = changeset) do
    case insert_job(record) do
      {:ok, job} ->
        Logger.debug("Enqueued record fast_track_checker job #{inspect(job.id)}")
        Changeset.change_attribute(changeset, :fast_track_checker_job_id, job.id)

      {:error, error} ->
        Logger.error("Failed to enqueue record fast_track_checker job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Record{id: id}) do
    %{id: id}
    |> Scheduler.FastTrackPublicationVerifier.new()
    |> Oban.insert()
  end
end
