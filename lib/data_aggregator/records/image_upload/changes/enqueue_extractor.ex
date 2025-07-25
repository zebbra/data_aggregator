defmodule DataAggregator.Records.ImageUpload.Changes.EnqueueExtractor do
  @moduledoc """
  Enqueues the extraction to be run by the 'DataAggregator.Records.ImageUpload.Workers.Extractor' worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Workers.Extractor

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_extractor(&1, ctx))
  end

  defp enqueue_extractor(%Changeset{data: image_upload} = changeset, %{actor: actor}) do
    case insert_job(image_upload, actor) do
      {:ok, job} ->
        Logger.debug("Enqueued image upload job #{inspect(job.id)}")
        changeset

      {:error, error} ->
        Logger.error("Failed to enqueue image upload job: #{inspect(error)}")
        Changeset.add_error(changeset, error)
    end
  end

  defp insert_job(%ImageUpload{id: id, collection_id: collection_id}, %User{id: user_id}) do
    %{id: id, collection_id: collection_id, user_id: user_id}
    |> Extractor.new()
    |> Oban.insert()
  end

  defp insert_job(%ImageUpload{id: id, collection_id: collection_id}, _) do
    %{id: id, collection_id: collection_id}
    |> Extractor.new()
    |> Oban.insert()
  end
end
