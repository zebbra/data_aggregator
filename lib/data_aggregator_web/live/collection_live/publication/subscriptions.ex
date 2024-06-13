defmodule DataAggregatorWeb.CollectionLive.Publication.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > publication subscriptions.
  """
  use Phoenix.LiveView

  import DataAggregatorWeb.CollectionLive.Publication.Helpers
  import DataAggregatorWeb.Gettext

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias Phoenix.LiveView.Socket

  require Logger

  @load load()
  @load_all load_all()
  @update_events ~w(set_running set_done set_failed)

  def subscribe_for_publication_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "publication:#{id}:created",
        "publication:#{id}:updated",
        "publication:#{id}:destroyed"
      ]

      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection -> publication updates: #{other}")
        socket
    end
  end

  def handle_notification(topic, event, notification, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "publication:#{id}:created" ->
        handle_publication_created(notification, socket)

      topic == "publication:#{id}:updated" and event in @update_events ->
        handle_publication_updated(notification, socket, event)

      topic == "publication:#{id}:destroyed" ->
        handle_publication_destroyed(notification, socket)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_publication_created(%Notification{data: publication}, socket) do
    publication = Records.load!(publication, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, publication, at: 0)}
  end

  defp handle_publication_updated(%Notification{data: %{id: id}}, socket, event) do
    publication = Publication.get_by_id!(id, load: @load_all)

    socket =
      socket
      |> maybe_assign_selected_publication(publication)
      |> set_notification(event)
      |> stream_insert(:results, publication, at: 0)

    {:noreply, socket}
  end

  defp handle_publication_destroyed(%Notification{data: publication}, socket) do
    {:noreply, stream_delete(socket, :results, publication)}
  end

  defp maybe_assign_selected_publication(%{assigns: %{selected_publication: nil}} = socket, _publication), do: socket

  defp maybe_assign_selected_publication(socket, publication), do: assign(socket, :selected_publication, publication)

  defp set_notification(socket, "set_failed") do
    put_flash(socket, :error, ~t"The publication failed, please try again"m)
  end

  defp set_notification(socket, "set_done") do
    put_flash(socket, :info, ~t"The publication has been completed"m)
  end

  defp set_notification(socket, _) do
    socket
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Publication.Subscriptions,
        only: [subscribe_for_publication_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
