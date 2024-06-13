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

  @import_update_events ~w(set_importing set_imported set_failed update_mapping)
  @export_update_events ~w(set_running set_exported set_failed)
  @encode_update_events ~w(set_encoding set_encoding_done)
  @publication_update_events ~w(set_running set_done set_failed)

  @busy_actions ~w(
    set_importing
    set_encoding
    set_running
  )

  def subscribe_for_record_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "record:#{id}:destroyed",
        "import:#{id}:updated",
        "export:#{id}:updated",
        "collection:updated:#{id}",
        "publication:#{id}:updated"
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

      topic == "import:#{id}:updated" and event in @import_update_events ->
        set_busy(socket, id, event, "dataset:import")

      topic == "export:#{id}:updated" and event in @export_update_events ->
        set_busy(socket, id, event, "collection:export")

      topic == "collection:updated:#{id}" and event in @encode_update_events ->
        set_busy(socket, id, event, "collection:encode")

      topic == "publication:#{id}:updated" and event in @publication_update_events ->
        %{data: %{channel: channel}} = notification

        busy_action =
          if channel == :approval do
            "collection:approval_pub"
          else
            "collection:fast_track_pub"
          end

        set_busy(socket, id, event, busy_action)

      true ->
        {:noreply, socket}
    end
  end

  defp set_busy(socket, _id, event, busy_action) when event in @busy_actions do
    socket
    |> assign(:busy, true)
    |> assign(:busy_action, busy_action)
    |> refresh()
  end

  defp set_busy(socket, id, event, _busy_action) do
    collection = get_collection(id)

    socket
    |> assign(:busy, collection.busy)
    |> assign(:busy_action, busy_action(collection))
    |> set_notification(event)
    |> refresh()
  end

  defp set_notification(socket, "set_encoding_done") do
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
