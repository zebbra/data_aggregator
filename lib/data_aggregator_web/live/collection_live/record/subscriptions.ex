defmodule DataAggregatorWeb.CollectionLive.Record.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > record subscriptions.
  """

  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes

  import DataAggregatorWeb.CollectionLive.Helpers
  import DataAggregatorWeb.Gettext

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias Phoenix.LiveView.Socket

  require Logger

  @collection_action_events ~w(
    set_importing
    set_exporting
    set_encoding
    set_fast_track_publishing
    set_approving
    set_idle
    set_idle_encoding
  )

  def subscribe_for_record_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "record:#{id}:destroyed",
        "collection:updated:#{id}"
      ]

      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection -> record updates: #{other}")
        socket
    end
  end

  defp handle_record_destroyed(%Notification{data: record}, socket) do
    {:noreply, stream_delete(socket, :results, record)}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_notification(topic, event, notification, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "record:#{id}:destroyed" ->
        handle_record_destroyed(notification, socket)

      topic == "collection:updated:#{id}" and event in @collection_action_events ->
        set_busy(socket, event)

      true ->
        {:noreply, socket}
    end
  end

  defp set_busy(socket, event) when event in ~w(set_idle set_idle_encoding) do
    socket
    |> assign(:busy, false)
    |> assign(:busy_action, nil)
    |> set_notification(event)
    |> refresh()
  end

  defp set_busy(socket, event) do
    socket
    |> assign(:busy, true)
    |> assign(:busy_action, busy_action(event))
    |> refresh()
  end

  defp set_notification(socket, "set_idle_encoding") do
    put_flash(socket, :info, ~t"The encoding process has been completed"m)
  end

  defp set_notification(socket, _) do
    socket
  end

  defp refresh(socket) do
    %{assigns: %{collection: %{id: id}, meta: %{pagify: pagify, opts: opts}}} = socket

    case Pagify.validate_and_run(Record, pagify, opts, id) do
      {:ok, {records, meta}} ->
        socket =
          socket
          |> assign(meta: meta)
          |> stream(:results, records, reset: true)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/records")}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Record.Subscriptions,
        only: [subscribe_for_record_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
