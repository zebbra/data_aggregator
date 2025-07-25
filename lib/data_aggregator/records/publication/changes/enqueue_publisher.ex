defmodule DataAggregator.Records.Publication.Changes.EnqueuePublisher do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.Publication.Workers.Publisher` worker with the given publication object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.Workers.Publisher

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_publisher(&1, ctx))
  end

  defp enqueue_publisher(%Changeset{data: publication} = changeset, %{actor: actor}) do
    case insert_job(publication, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued publication job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue publication job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Publication{id: id, collection_id: collection_id}, nil) do
    %{id: id, collection_id: collection_id}
    |> Publisher.new()
    |> Oban.insert()
  end

  defp insert_job(%Publication{id: id, collection_id: collection_id}, %User{id: user_id}) do
    %{id: id, collection_id: collection_id, user_id: user_id}
    |> Publisher.new()
    |> Oban.insert()
  end
end
