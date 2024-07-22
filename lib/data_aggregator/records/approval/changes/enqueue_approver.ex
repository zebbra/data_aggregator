defmodule DataAggregator.Records.Approval.Changes.EnqueueApprover do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.Approval.Workers.Approver` worker with the given approval object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Approval

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue/1)
  end

  defp enqueue(%Changeset{data: approval} = changeset) do
    case insert_job(approval) do
      {:ok, job} ->
        Logger.debug("Enqueued approval job #{inspect(job.id)}")
        Changeset.change_attribute(changeset, :job_id, job.id)

      {:error, error} ->
        Logger.error("Failed to enqueue approval job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Approval{id: id}) do
    %{id: id}
    |> Approval.Workers.Approver.new()
    |> Oban.insert()
  end
end
