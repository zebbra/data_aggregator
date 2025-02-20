defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Subscriptions do
  @moduledoc """
  This module contains helper functions for the colleciton > image upload subscriptions.
  """
  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection_light: 2, busy_action: 1]
  import DataAggregatorWeb.CollectionLive.ImageUpload.Helpers
  import DataAggregatorWeb.Helpers, only: [get_actor: 1, get_tenant: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ImageUpload
  alias Phoenix.LiveView.Socket

  require Logger

  @load_all load_all()

  @image_upload_update_events ~w(set_extracting set_extracted set_extraction_failed set_mapping set_mapped set_mapping_incomplete set_mapping_failed)
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

  def subscribe_for_image_upload_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "image_upload:#{id}:created",
        "image_upload:#{id}:updated",
        "image_upload:#{id}:destroyed",
        "collection:updated:#{id}"
      ]

      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection -> image upload updates: #{other}")
        socket
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_notification(topic, event, notification, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "image_upload:#{id}:created" ->
        handle_image_upload_created(notification, socket)

      topic == "image_upload:#{id}:updated" and event in @image_upload_update_events ->
        handle_image_upload_updated(notification, socket)

      topic == "image_upload:#{id}:destroyed" ->
        handle_image_upload_destroyed(notification, socket)

      topic == "collection:updated:#{id}" and event in @collection_action_events ->
        set_busy(socket, event)

      true ->
        Logger.warning("Unknown topic: #{topic}")
        {:noreply, socket}
    end
  end

  defp handle_image_upload_created(%Notification{data: image_upload}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    image_upload =
      ImageUpload.get_by_id!(image_upload.id, load: @load_all, actor: actor, tenant: tenant)

    {:noreply, stream_insert(socket, :results, image_upload, at: 0)}
  end

  defp handle_image_upload_updated(%Notification{data: %{id: id, collection_id: collection_id}}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    image_upload = ImageUpload.get_by_id!(id, load: @load_all, actor: actor, tenant: tenant)
    collection = get_collection_light(collection_id, actor)

    socket =
      socket
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> maybe_assign_selected_image_upload(image_upload)
      |> stream_insert(:results, image_upload, at: 0)

    {:noreply, socket}
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

  defp handle_image_upload_destroyed(%Notification{data: image_upload}, socket) do
    {:noreply, stream_delete(socket, :results, image_upload)}
  end

  defp maybe_assign_selected_image_upload(%{assigns: %{selected_image_upload: nil}} = socket, _image_upload), do: socket

  defp maybe_assign_selected_image_upload(socket, image_upload), do: assign(socket, :selected_image_upload, image_upload)

  defp refresh(socket) do
    %{assigns: %{collection: %{id: id}, meta: %{ash_pagify: ash_pagify, opts: opts}}} = socket

    case AshPagify.validate_and_run(ImageUpload, ash_pagify, opts, id) do
      {:ok, {records, meta}} ->
        socket =
          socket
          |> assign(meta: meta)
          |> stream(:results, records, reset: true)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/image_uploads")}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.ImageUpload.Subscriptions,
        only: [subscribe_for_image_upload_updates: 2, handle_notification: 4]

      @impl true
      def handle_info({topic, event, notification}, socket) do
        handle_notification(topic, event, notification, socket)
      end
    end
  end
end
