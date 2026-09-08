defmodule DataAggregator.Files.Attachment.Changes.DeleteFile do
  @moduledoc """
  This change registers an `after_action` hook to delete a file from `DataAggregator.Files.Store`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &delete_file/2)
  end

  @impl true
  def after_batch(changesets_and_results, _opts, _context) do
    Enum.each(changesets_and_results, fn {changeset, attachment} ->
      delete_file(changeset, attachment)
    end)

    :ok
  end

  defp delete_file(%Changeset{}, %Attachment{filename: filename} = attachment) do
    :ok = Store.delete({filename, attachment})

    Logger.debug("Deleted file #{filename} with id #{attachment.id}")

    {:ok, attachment}
  rescue
    error ->
      Logger.error("Exception while deleting file #{filename} with id #{attachment.id}: #{inspect(error)}")

      # Still return ok to not break the batch
      {:ok, attachment}
  end
end
