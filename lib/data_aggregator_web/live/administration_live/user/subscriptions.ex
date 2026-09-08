defmodule DataAggregatorWeb.AdministrationLive.User.Subscriptions do
  @moduledoc """
  This module contains helper functions for the administration subscriptions.
  """

  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes

  import DataAggregatorWeb.Helpers, only: [get_actor: 1]

  alias Ash.Error.Invalid
  alias Ash.Error.Query.NotFound
  alias Ash.Notifier.Notification
  alias DataAggregator.Accounts.User
  alias DataAggregator.PubSub

  require Logger

  def subscribe_for_administration_updates(socket, connected) do
    case connected do
      true ->
        topic = [
          "user:created",
          "user:updated",
          "user:destroyed"
        ]

        PubSub.subscribe(topic)
        socket

      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for administration updates: #{other}")
        socket
    end
  end

  def handle_notification(topic, _event, notification, socket) do
    cond do
      topic == "user:created" ->
        handle_user_created(notification, socket)

      topic == "user:updated" ->
        handle_user_updated(notification, socket)

      topic == "user:destroyed" ->
        handle_user_destroyed(notification, socket)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_user_created(%Notification{data: %{id: id}}, socket) do
    user = User.get_by_id!(id, actor: get_actor(socket))
    {:noreply, stream_insert(socket, :results, user, at: 0)}
  rescue
    # Ignore if the user was not found --> it was deleted or not accessible
    _error in [NotFound, Invalid] -> {:noreply, socket}
  end

  defp handle_user_updated(%Notification{data: %{id: id}}, socket) do
    user = User.get_by_id!(id, actor: get_actor(socket))
    {:noreply, stream_insert(socket, :results, user, at: 0)}
  rescue
    # Ignore if the user was not found --> it was deleted
    _error in [NotFound, Invalid] -> {:noreply, socket}
  end

  defp handle_user_destroyed(%Notification{data: user}, socket) do
    {:noreply, stream_delete(socket, :results, user)}
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.AdministrationLive.User.Subscriptions,
        only: [subscribe_for_administration_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
