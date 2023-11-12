defmodule DataAggregator.Files.Attachment.Changes.DeleteFile do
  @moduledoc """
  This change registers an `after_action` hook to delete a file from `DataAggregator.Files.Store`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.after_action(&delete_file/2, append: true)
  end

  defp delete_file(%Changeset{}, %Attachment{filename: filename} = attachment) do
    :ok = Store.delete({filename, attachment})
    Logger.info("Deleted file #{filename} with id #{attachment.id}")
    {:ok, attachment}
  end
end
