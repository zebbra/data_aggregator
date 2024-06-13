defmodule DataAggregatorWeb.CollectionLive.Import.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > import subscriptions.
  """
  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes

  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1, busy_action: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers
  import DataAggregatorWeb.Gettext

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias Phoenix.LiveView.Socket

  require Logger

  @load_all load_all()
  @import_update_events ~w(set_importing set_imported set_failed update_mapping)
  @export_update_events ~w(set_running set_exported set_failed)
  @encode_update_events ~w(set_encoding set_encoding_done)
  @publication_update_events ~w(set_running set_done set_failed)

  @busy_actions ~w(
    set_encoding
    set_running
  )

  def subscribe_for_import_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "import:#{id}:created",
        "import:#{id}:updated",
        "import:#{id}:destroyed",
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
        Logger.warning("Unable to subscribe for collection -> import updates: #{other}")
        socket
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_notification(topic, event, notification, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "import:#{id}:created" ->
        handle_import_created(notification, socket)

      topic == "import:#{id}:updated" and event in @import_update_events ->
        handle_import_updated(notification, socket, event)

      topic == "export:#{id}:updated" and event in @export_update_events ->
        set_busy(socket, id, event)

      topic == "collection:updated:#{id}" and event in @encode_update_events ->
        set_busy(socket, id, event)

      topic == "publication:#{id}:updated" and event in @publication_update_events ->
        set_busy(socket, id, event)

      topic == "import:#{id}:destroyed" ->
        handle_import_destroyed(notification, socket)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_import_created(%Notification{data: import}, socket) do
    import = Import.get_by_id!(import.id, load: @load_all)
    {:noreply, stream_insert(socket, :results, import, at: 0)}
  end

  defp handle_import_updated(%Notification{data: %{id: id, collection_id: collection_id}}, socket, event) do
    import = Import.get_by_id!(id, load: @load_all)
    collection = get_collection(collection_id)

    socket =
      socket
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> maybe_assign_selected_import(import)
      |> set_notification(event)
      |> stream_insert(:results, import, at: 0)

    {:noreply, socket}
  end

  defp set_busy(socket, _id, event) when event in @busy_actions do
    socket
    |> assign(:busy, true)
    |> assign(:busy_action, nil)
    |> refresh()
  end

  defp set_busy(socket, id, _event) do
    collection = get_collection(id)

    socket
    |> assign(:busy, collection.busy)
    |> assign(:busy_action, busy_action(collection))
    |> refresh()
  end

  defp handle_import_destroyed(%Notification{data: import}, socket) do
    {:noreply, stream_delete(socket, :results, import)}
  end

  defp maybe_assign_selected_import(%{assigns: %{selected_import: nil}} = socket, _import), do: socket

  defp maybe_assign_selected_import(socket, import), do: assign(socket, :selected_import, import)

  defp set_notification(socket, "set_failed") do
    put_flash(socket, :error, ~t"The import failed, please try again"m)
  end

  defp set_notification(socket, "set_imported") do
    put_flash(socket, :info, ~t"The import has been completed"m)
  end

  defp set_notification(socket, _) do
    socket
  end

  defp refresh(socket) do
    %{assigns: %{collection: %{id: id}, meta: %{pagify: pagify, opts: opts}}} = socket

    case Pagify.validate_and_run(Import, pagify, opts, id) do
      {:ok, {records, meta}} ->
        socket =
          socket
          |> assign(meta: meta)
          |> stream(:results, records, reset: true)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/imports")}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Import.Subscriptions,
        only: [subscribe_for_import_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
