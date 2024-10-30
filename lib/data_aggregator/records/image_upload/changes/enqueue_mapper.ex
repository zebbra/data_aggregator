defmodule DataAggregator.Records.ImageUpload.Changes.EnqueueMapper do
  @moduledoc """
  Enqueues the mapping to be run by the 'DataAggregator.Records.ImageUpload.Workers.Mapper' worker.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Workers.Mapper

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &enqueue_mapper(&1, ctx))
  end

  defp enqueue_mapper(%Changeset{data: image_upload} = changeset, %{actor: actor}) do
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
    |> Mapper.new()
    |> Oban.insert()
  end

  defp insert_job(%ImageUpload{id: id, collection_id: collection_id}, _) do
    %{id: id, collection_id: collection_id}
    |> Mapper.new()
    |> Oban.insert()
  end
end
