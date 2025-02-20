defmodule DataAggregatorWeb.CollectionLive.Export.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > export subscriptions.
  """
  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.CollectionLive.Export.Helpers
  import DataAggregatorWeb.CollectionLive.Helpers, only: [busy_action: 1]
  import DataAggregatorWeb.Helpers, only: [get_tenant: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export
  alias Phoenix.LiveView.Socket

  require Logger

  @load load()
  @load_all load_all()
  @update_events ~w(set_running set_exported set_failed add_export_progress)
  @collection_action_events ~w(
    set_mapping
    set_importing
    set_exporting
    set_encoding
    set_fast_track_publishing
    set_validating
    set_idle
    set_idle_encoding
  )

  def subscribe_for_export_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "export:#{id}:created",
        "export:#{id}:updated",
        "export:#{id}:destroyed",
        "collection:updated:#{id}"
      ]

      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection -> export updates: #{other}")
        socket
    end
  end

  def handle_notification(topic, event, notification, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "export:#{id}:created" ->
        handle_export_created(notification, socket)

      topic == "export:#{id}:updated" and event in @update_events ->
        handle_export_updated(notification, socket, event)

      topic == "export:#{id}:destroyed" ->
        handle_export_destroyed(notification, socket)

      topic == "collection:updated:#{id}" and event in @collection_action_events ->
        set_busy(socket, event)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_export_created(%Notification{data: export}, socket) do
    export = Ash.load!(export, @load, lazy?: true, tenant: get_tenant(socket))
    {:noreply, stream_insert(socket, :results, export, at: 0)}
  end

  defp handle_export_updated(%Notification{data: %{id: id}}, socket, event) do
    export = Export.get_by_id!(id, load: @load_all, tenant: get_tenant(socket))

    socket =
      socket
      |> maybe_assign_selected_export(export)
      |> set_notification(event)
      |> stream_insert(:results, export, at: 0)

    {:noreply, socket}
  end

  defp handle_export_destroyed(%Notification{data: export}, socket) do
    {:noreply, stream_delete(socket, :results, export)}
  end

  defp set_busy(socket, event) when event in ~w(set_idle set_idle_encoding) do
    socket
    |> assign(:busy, false)
    |> assign(:busy_action, nil)
    |> refresh()
  end

  defp set_busy(socket, event) do
    socket
    |> assign(:busy, true)
    |> assign(:busy_action, busy_action(event))
    |> refresh()
  end

  defp maybe_assign_selected_export(%{assigns: %{selected_export: nil}} = socket, _export), do: socket

  defp maybe_assign_selected_export(socket, export) do
    if socket.assigns.selected_export.id == export.id do
      assign(socket, :selected_export, export)
    else
      socket
    end
  end

  defp set_notification(socket, "set_failed") do
    put_flash(socket, :error, ~t"The export failed, please try again"m)
  end

  defp set_notification(socket, "set_exported") do
    put_flash(socket, :info, ~t"The export has been completed"m)
  end

  defp set_notification(socket, _) do
    socket
  end

  defp refresh(socket) do
    %{assigns: %{collection: %{id: id}, meta: %{ash_pagify: ash_pagify, opts: opts}}} = socket

    case AshPagify.validate_and_run(Export, ash_pagify, opts, id) do
      {:ok, {records, meta}} ->
        socket =
          socket
          |> assign(meta: meta)
          |> stream(:results, records, reset: true)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/exports")}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Export.Subscriptions,
        only: [subscribe_for_export_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
