defmodule DataAggregator.Records.Record.Changes.EnqueueEncoder do
  @moduledoc """
  Enques the record to be processed by the `DataAggregator.Records.Record.Workers.Encoder` worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &enqueue_encoder/1)
  end

  defp enqueue_encoder(%Changeset{data: record} = changeset) do
    case insert_job(record) do
      {:ok, job} ->
        Logger.info("Enqueued record encoding job #{inspect(job.id)}")
        # Changeset.change_attribute(changeset, :encoder_job_id, job.id)
        Changeset.manage_relationship(changeset, :encoder_job, job)

      {:error, error} ->
        Logger.error("Failed to enqueue record encoding job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Record{id: id}) do
    %{id: id}
    |> Record.Workers.Encoder.new()
    |> Oban.insert()
  end
end
