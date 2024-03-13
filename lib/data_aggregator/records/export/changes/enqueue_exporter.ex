defmodule DataAggregator.Records.Changes.EnqueueExporter do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Records.Export.Workers.Exporter` worker with the given export object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Export

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue_exporter/1)
  end

  defp enqueue_exporter(%Changeset{data: export} = changeset) do
    case insert_job(export) do
      {:ok, job} ->
        Logger.debug("Enqueued export job #{inspect(job.id)}")
        Changeset.change_attribute(changeset, :job_id, job.id)

      {:error, error} ->
        Logger.error("Failed to enqueue export job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp enqueue_exporter({:error, error}) do
    {:error, error}
  end

  defp insert_job(%Export{id: id}) do
    %{id: id}
    |> Export.Workers.Exporter.new()
    |> Oban.insert()
  end
end
