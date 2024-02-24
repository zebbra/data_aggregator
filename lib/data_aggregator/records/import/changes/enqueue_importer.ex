defmodule DataAggregator.Records.Import.Changes.EnqueueImporter do
  @moduledoc """
  Enques the import to be run by the `DataAggregator.Records.Import.Workers.Importer` worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue_importer/1)
  end

  defp enqueue_importer(%Changeset{data: import} = changeset) do
    case insert_job(import) do
      {:ok, job} ->
        Logger.debug("Enqueued import job #{inspect(job.id)}")
        Changeset.change_attribute(changeset, :job_id, job.id)

      {:error, error} ->
        Logger.error("Failed to enqueue import job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Import{id: id}) do
    %{id: id}
    |> Import.Workers.Importer.new()
    |> Oban.insert()
  end
end
