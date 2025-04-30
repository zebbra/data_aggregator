defmodule DataAggregator.Records.Record.Actions.EnqueuePublicationVerifier do
  @moduledoc """
  Enques the record to be processed by the `DataAggregator.Records.Publication.Scheduler.PublicationVerifier` worker.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Publication.Scheduler
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, ctx) do
    enqueue_publication_verifier(input.arguments.published_record, ctx)
  end

  defp enqueue_publication_verifier(record, %{actor: actor}) do
    case insert_job(record, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued record publication_verifier job #{inspect(job.id)}")
        {:ok, job}

      {:error, error} ->
        Logger.error("Failed to enqueue record publication_verifier job: #{inspect(error)}")
        {:error, error}
    end
  end

  defp insert_job(%Record{id: id, collection_id: collection_id}, user) do
    %{id: id, collection_id: collection_id, user_id: maybe_get_id(user)}
    |> Scheduler.PublicationVerifier.new(
      unique: [
        period: :infinity,
        fields: [:args, :worker],
        keys: [:id, :collection_id]
      ],
      replace: [scheduled: [:scheduled_at]],
      schedule_in: {2, :hours}
    )
    |> Oban.insert()
  end

  defp insert_job(%PublishedRecord{record_id: id, collection_id: collection_id}, user) do
    %{id: id, collection_id: collection_id, user_id: maybe_get_id(user)}
    |> Scheduler.PublicationVerifier.new(
      unique: [
        period: :infinity,
        fields: [:args, :worker],
        keys: [:id, :collection_id]
      ],
      replace: [scheduled: [:scheduled_at]],
      schedule_in: {2, :hours}
    )
    |> Oban.insert()
  end

  defp maybe_get_id(nil), do: nil
  defp maybe_get_id(%{id: id}), do: id
end
