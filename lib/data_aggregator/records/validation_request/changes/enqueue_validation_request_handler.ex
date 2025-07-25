defmodule DataAggregator.Records.ValidationRequest.Changes.EnqueueValidationRequestHandler do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler` worker with the given ValidationRequest object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_validation_request_handler(&1, ctx))
  end

  defp enqueue_validation_request_handler(%Changeset{data: validation_request} = changeset, %{actor: actor}) do
    case insert_job(validation_request, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued validation request job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue validation request job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%ValidationRequest{id: id, collection_id: collection_id}, nil) do
    %{id: id, collection_id: collection_id}
    |> ValidationRequestHandler.new()
    |> Oban.insert()
  end

  defp insert_job(%ValidationRequest{id: id, collection_id: collection_id}, %User{id: user_id}) do
    %{id: id, collection_id: collection_id, user_id: user_id}
    |> ValidationRequestHandler.new()
    |> Oban.insert()
  end
end
