defmodule DataAggregator.Records.Collection.Changes.EnqueueRecordsEnqueuer do
  @moduledoc """
  Enqueues the task to be processed by the `DataAggregator.Records.Collection.Workers.BatchRecordsEnqueuer` worker.
  This is mandatory so that we can cancel an encoding.

  The worker will create batch encoding jobs, where each job processes multiple records
  for improved performance over single-record encoding.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Workers.BatchRecordsEnqueuer

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_records_enqueuer(&1, ctx))
  end

  defp enqueue_records_enqueuer(%Changeset{data: collection} = changeset, %{actor: actor}) do
    query = Changeset.get_argument(changeset, :query)

    case insert_job(collection, query, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued records enqueuer job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue records enqueuer job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Collection{id: id}, %{} = query, %User{id: user_id}) do
    %{id: id, collection_id: id, query: query, user_id: user_id}
    |> BatchRecordsEnqueuer.new()
    |> Oban.insert()
  end

  defp insert_job(%Collection{id: id}, %{} = query, _) do
    %{id: id, collection_id: id, query: query}
    |> BatchRecordsEnqueuer.new()
    |> Oban.insert()
  end
end
