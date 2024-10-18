defmodule DataAggregator.Records.Import.Changes.EnqueueImporter do
  @moduledoc """
  Enques the import to be run by the `DataAggregator.Records.Import.Workers.Importer` worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Workers.Importer

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_importer(&1, ctx))
  end

  defp enqueue_importer(%Changeset{data: import} = changeset, %{actor: actor}) do
    case insert_job(import, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued import job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue import job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%Import{id: id, collection_id: collection_id}, %User{id: user_id}) do
    %{id: id, collection_id: collection_id, user_id: user_id}
    |> Importer.new()
    |> Oban.insert()
  end

  defp insert_job(%Import{id: id, collection_id: collection_id}, _) do
    %{id: id, collection_id: collection_id}
    |> Importer.new()
    |> Oban.insert()
  end
end
