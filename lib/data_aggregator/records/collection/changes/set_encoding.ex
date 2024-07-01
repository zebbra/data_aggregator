defmodule DataAggregator.Records.Collection.Changes.SetEncoding do
  @moduledoc """
  Manually track the encoding status of a collection.

  You can subscribe to the `:set_encoding` and `:set_idle_encoding` events
  to get notified when the encoding is started and finished.

  This change will start a polling process to check the encoding status
  of the collections records_count_encoding counter and update the collection
  (call the `:set_idle_encoding` update) once the encoding is done.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &schedule_poller/2)
  end

  defp schedule_poller(_changeset, collection) do
    if DataAggregator.Records.execute_async?() do
      Task.start(fn -> await_encoded(collection.id) end)
    else
      Logger.debug("not executing if execute_async is false (likely in tests), skipping")
    end

    {:ok, collection}
  end

  defp await_encoded(id) do
    :timer.sleep(5_000)
    collection = Collection.get_by_id!(id, load: [:records_count_encoding])

    if collection.records_count_encoding == 0 do
      Collection.set_idle_encoding(collection)
    else
      await_encoded(id)
    end
  end
end
