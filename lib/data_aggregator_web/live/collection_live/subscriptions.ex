defmodule DataAggregatorWeb.CollectionLive.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection subscriptions.
  """

  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes

  import DataAggregatorWeb.CollectionLive.Helpers
  import DataAggregatorWeb.Helpers, only: [get_actor: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection

  require Logger

  @load load()

  def subscribe_for_collection_updates(socket, connected) do
    case connected do
      true ->
        topic = [
          "collection:created",
          "collection:updated",
          "collection:destroyed"
        ]

        PubSub.subscribe(topic)
        socket

      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection updates: #{other}")
        socket
    end
  end

  def handle_notification(topic, _event, notification, socket) do
    cond do
      topic == "collection:created" ->
        handle_collection_created(notification, socket)

      topic == "collection:updated" ->
        handle_collection_updated(notification, socket)

      topic == "collection:destroyed" ->
        handle_collection_destroyed(notification, socket)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_collection_created(%Notification{data: %{id: id}}, socket) do
    collection = Collection.get_by_id!(id, load: @load, actor: get_actor(socket))
    {:noreply, stream_insert(socket, :results, collection, at: 0)}
  end

  defp handle_collection_updated(%Notification{data: %{id: id}}, socket) do
    collection = Collection.get_by_id!(id, load: @load, actor: get_actor(socket))
    {:noreply, stream_insert(socket, :results, collection, at: 0)}
  rescue
    # Ignore if the collection was not found --> it was deleted
    _error in [Ash.Error.Query.NotFound] -> {:noreply, socket}
  end

  defp handle_collection_destroyed(%Notification{data: collection}, socket) do
    {:noreply, stream_delete(socket, :results, collection)}
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Subscriptions,
        only: [subscribe_for_collection_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
