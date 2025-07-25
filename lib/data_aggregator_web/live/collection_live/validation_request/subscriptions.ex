defmodule DataAggregatorWeb.CollectionLive.ValidationRequest.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > validation_request subscriptions.
  """
  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.CollectionLive.Helpers, only: [busy_action: 1]
  import DataAggregatorWeb.CollectionLive.ValidationRequest.Helpers
  import DataAggregatorWeb.Helpers, only: [get_tenant: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationRequest
  alias Phoenix.LiveView.Socket

  require Logger

  @load load()
  @load_all load_all()
  @update_events ~w(set_running set_done set_failed add_validation_request_progress)
  @collection_action_events ~w(
    set_mapping
    set_importing
    set_exporting
    set_encoding
    set_publishing
    set_validating
    set_idle
    set_idle_encoding
  )

  def subscribe_for_validation_request_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "validation_request:#{id}:created",
        "validation_request:#{id}:updated",
        "validation_request:#{id}:destroyed",
        "collection:updated:#{id}"
      ]

      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection -> validation_request updates: #{other}")

        socket
    end
  end

  def handle_notification(topic, event, notification, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "validation_request:#{id}:created" ->
        handle_validation_request_created(notification, socket)

      topic == "validation_request:#{id}:updated" and event in @update_events ->
        handle_validation_request_updated(notification, socket, event)

      topic == "validation_request:#{id}:destroyed" ->
        handle_validation_request_destroyed(notification, socket)

      topic == "collection:updated:#{id}" and event in @collection_action_events ->
        set_busy(socket, event)

      true ->
        {:noreply, socket}
    end
  end

  defp handle_validation_request_created(%Notification{data: validation_request}, socket) do
    tenant = get_tenant(socket)
    validation_request = Ash.load!(validation_request, @load, lazy?: true, tenant: tenant)
    {:noreply, stream_insert(socket, :results, validation_request, at: 0)}
  end

  defp handle_validation_request_updated(%Notification{data: %{id: id}}, socket, event) do
    tenant = get_tenant(socket)
    validation_request = ValidationRequest.get_by_id!(id, load: @load_all, tenant: tenant)

    socket =
      socket
      |> maybe_assign_selected_validation_request(validation_request)
      |> set_notification(event)
      |> stream_insert(:results, validation_request, at: 0)

    {:noreply, socket}
  end

  defp handle_validation_request_destroyed(%Notification{data: validation_request}, socket) do
    {:noreply, stream_delete(socket, :results, validation_request)}
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

  defp maybe_assign_selected_validation_request(
         %{assigns: %{selected_validation_request: nil}} = socket,
         _validation_request
       ),
       do: socket

  defp maybe_assign_selected_validation_request(socket, validation_request),
    do: assign(socket, :selected_validation_request, validation_request)

  defp set_notification(socket, "set_failed") do
    put_flash(socket, :error, ~t"The validation request failed, please try again"m)
  end

  defp set_notification(socket, "set_done") do
    put_flash(socket, :info, ~t"The validation request has been completed"m)
  end

  defp set_notification(socket, _) do
    socket
  end

  defp refresh(socket) do
    %{assigns: %{collection: %{id: id}, meta: %{ash_pagify: ash_pagify, opts: opts}}} = socket

    case AshPagify.validate_and_run(ValidationRequest, ash_pagify, opts, id) do
      {:ok, {records, meta}} ->
        socket =
          socket
          |> assign(meta: meta)
          |> stream(:results, records, reset: true)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/validations")}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.ValidationRequest.Subscriptions,
        only: [subscribe_for_validation_request_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
