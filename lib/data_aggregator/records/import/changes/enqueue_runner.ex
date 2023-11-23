defmodule DataAggregator.Records.Import.Changes.EnqueueRunner do
  @moduledoc """
  Enques the import to be run by the `DataAggregator.Records.Import.Runner` worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &enqueue_runner/2)

    # changeset |> Changeset.after_action(&enqueue_runner/2)
  end

  defp enqueue_runner(_changeset, {:ok, %Import{id: id} = import}) do
    %{id: id}
    |> Import.Runner.new()
    |> Oban.insert()
    |> case do
      {:ok, _job} -> {:ok, import}
      {:error, reason} -> {:error, reason}
    end
  end

  defp enqueue_runner(_changeset, {:error, error}) do
    Logger.error(error)
    {:error, error}
  end
end
