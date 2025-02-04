defmodule DataAggregator.Records.Validation.Changes.EnqueueValidater do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.Validation.Workers.Validater` worker with the given validation object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Validation

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue/1)
  end

  defp enqueue(%Changeset{data: validation} = changeset) do
    case insert_job(validation) do
      {:ok, job} ->
        Logger.debug("Enqueued validation job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue validation job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Validation{id: id, collection_id: collection_id}) do
    %{id: id, collection_id: collection_id}
    |> Validation.Workers.Validater.new()
    |> Oban.insert()
  end
end
