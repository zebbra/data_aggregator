defmodule DataAggregator.Records.Record.Changes.EnqueueEncoder do
  @moduledoc """
  Enques the record to be processed by the `DataAggregator.Records.Record.Workers.Encoder` worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_encoder(&1, ctx))
  end

  defp enqueue_encoder(%Changeset{data: record} = changeset, %{actor: actor}) do
    case insert_job(record, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued record encoding job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue record encoding job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Record{id: id, collection_id: collection_id}, %User{id: user_id}) do
    %{id: id, collection_id: collection_id, user_id: user_id}
    |> Encoder.new()
    |> Oban.insert()
  end

  defp insert_job(%Record{id: id, collection_id: collection_id}, _) do
    %{id: id, collection_id: collection_id}
    |> Encoder.new()
    |> Oban.insert()
  end
end
