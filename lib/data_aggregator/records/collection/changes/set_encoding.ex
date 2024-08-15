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
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &schedule_poller/2)
  end

  defp schedule_poller(_changeset, collection) do
    if Records.execute_async?() do
      Task.start(fn -> insert_job(collection) end)
    else
      Logger.debug("not executing if execute_async is false (likely in tests), skipping")
    end

    {:ok, collection}
  end

  defp insert_job(%Collection{id: id}) do
    %{id: id}
    |> Collection.Workers.EncodingStatePoller.new()
    |> Oban.insert()
  end
end
