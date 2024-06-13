defmodule DataAggregator.Records.Collection.Changes.SetEncoding do
  @moduledoc """
  Manually track the encoding status of a collection.

  You can subscribe to the `:set_encoding` and `:set_encoding_done` events
  to get notified when the encoding is started and finished.

  This change will start a polling process to check the encoding status
  of the collections records_count_encoding counter and update the collection
  (call the `:set_encoding_done` update) once the encoding is done.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    id = Changeset.get_attribute(changeset, :id)
    collection = Collection.get_by_id!(id, load: [:records_count_encoding])

    if collection.records_count_encoding > 0 do
      Changeset.add_error(changeset, message: "Collection is already encoding")
    else
      changeset
      |> Changeset.after_action(&schedule_poller/2)
      |> Changeset.force_change_attribute(:updated_at, DateTime.utc_now())
    end
  end

  defp schedule_poller(_changeset, collection) do
    Task.start(fn -> await_encoded(collection.id) end)
    {:ok, collection}
  end

  defp await_encoded(id) do
    :timer.sleep(5_000)
    collection = Collection.get_by_id!(id, load: [:records_count_encoding])

    if collection.records_count_encoding == 0 do
      Collection.set_encoding_done(collection)
    else
      await_encoded(id)
    end
  end
end
