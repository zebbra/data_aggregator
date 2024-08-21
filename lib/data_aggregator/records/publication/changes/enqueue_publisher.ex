defmodule DataAggregator.Records.Publication.Changes.EnqueuePublisher do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.Publication.Workers.Publisher` worker with the given publication object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Publication

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue_publisher/1)
  end

  defp enqueue_publisher(%Changeset{data: publication} = changeset) do
    case insert_job(publication) do
      {:ok, job} ->
        Logger.debug("Enqueued publication job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue publication job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Publication{id: id}) do
    %{id: id}
    |> Publication.Workers.Publisher.new()
    |> Oban.insert()
  end
end
