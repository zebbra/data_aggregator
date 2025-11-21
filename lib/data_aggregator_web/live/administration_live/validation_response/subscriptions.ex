defmodule DataAggregatorWeb.AdministrationLive.ValidationResponse.Subscriptions do
  @moduledoc """
  This module contains subscriptions for the ValidationResponse resource.
  """

  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.AdministrationLive.ValidationResponse.Helpers
  import DataAggregatorWeb.Helpers, only: [get_actor: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.ValidationResponse

  require Logger

  @load load()

  def subscribe_for_validation_response_updates(socket, connected) do
    case connected do
      true ->
        topic = [
          "validation_response:created",
          "validation_response:updated",
          "validation_response:destroyed"
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
      topic == "validation_response:created" ->
        handle_validation_response_created(notification, socket)

      topic == "validation_response:updated" ->
        handle_validation_response_updated(notification, socket)

      topic == "validation_response:destroyed" ->
        handle_validation_response_destroyed(notification, socket)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_validation_response_created(%Notification{data: %{id: id}}, socket) do
    validation_response = ValidationResponse.get_by_id!(id, actor: get_actor(socket), load: @load)
    {:noreply, stream_insert(socket, :results, validation_response, at: 0)}
  end

  defp handle_validation_response_updated(%Notification{data: %{id: id}}, socket) do
    validation_response = ValidationResponse.get_by_id!(id, actor: get_actor(socket), load: @load)

    socket =
      socket
      |> stream_insert(:results, validation_response, at: 0)
      |> maybe_assign_selected_validation_response(validation_response)

    {:noreply, socket}
  end

  defp handle_validation_response_destroyed(%Notification{data: validation_response}, socket) do
    {:noreply, stream_delete(socket, :results, validation_response)}
  end

  defp maybe_assign_selected_validation_response(
         %{assigns: %{selected_validation_response: nil}} = socket,
         _validation_response
       ), do: socket

  defp maybe_assign_selected_validation_response(socket, validation_response),
    do: assign(socket, :selected_validation_response, validation_response)

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.AdministrationLive.ValidationResponse.Subscriptions,
        only: [subscribe_for_validation_response_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
