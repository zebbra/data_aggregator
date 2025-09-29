defmodule DataAggregator.Records.ValidationResponse.Changes.EnqueueValidationResponseHandler do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandler` worker with the given ValidationResponse object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ValidationResponse

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, %{actor: actor}) do
    Changeset.before_action(changeset, &enqueue(&1, actor))
  end

  defp enqueue(%Changeset{data: validation_response} = changeset, actor) do
    case insert_job(validation_response, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued validation response job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue validation response job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%ValidationResponse{id: id}, actor) do
    %{id: id, user_id: actor.id}
    |> ValidationResponse.Workers.ValidationResponseHandler.new()
    |> Oban.insert()
  end
end
