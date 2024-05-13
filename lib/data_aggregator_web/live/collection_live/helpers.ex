defmodule DataAggregatorWeb.CollectionLive.Helpers do
  @moduledoc """
  This module contains helper functions for the collection live view.
  """

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias Phoenix.LiveView.Socket

  require Logger

  def subscribe_for_collection_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = "collection:updated:#{id}"
      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection updates: #{other}")
        socket
    end
  end

  def get_collection(id) do
    Collection.get_by_id!(id,
      load: [
        :records_count,
        :digitizing_progress,
        :encoding_state,
        :records_count_not_encoded,
        :records_count_failed,
        :records_publishing
      ]
    )
  end
end
