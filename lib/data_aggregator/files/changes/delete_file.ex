defmodule DataAggregator.Files.Changes.DeleteFile do
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.after_action(&delete_file/2, append: true)
  end

  defp delete_file(%Changeset{}, %Attachment{id: id, filename: filename} = attachment) do
    :ok = Store.delete({filename, id})
    Logger.info("Deleted file #{filename} with id #{id}")
    {:ok, attachment}
  end
end
