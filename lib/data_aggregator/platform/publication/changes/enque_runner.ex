defmodule DataAggregator.Platform.Publication.Changes.EnqueueRunner do
  @moduledoc """
  Enques a job to run by the `DataAggregator.Platform.Publication.Export.Runner` worker with the given export object as parameter
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Publication.Export

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &enqueue_runner/2)
  end

  defp enqueue_runner(_changeset, {:ok, %Export{id: id} = export}) do
    %{id: id}
    |> Export.Runner.new()
    |> Oban.insert()
    |> case do
      {:ok, _job} -> {:ok, export}
      {:error, reason} -> {:error, reason}
    end
  end

  defp enqueue_runner(_changeset, {:error, error}) do
    {:error, error}
  end
end
