defmodule DataAggregatorWeb.CollectionLive.Record.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > record subscriptions.
  """

  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.CollectionLive.Helpers
  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [maybe_put_tsvector: 2]
  import DataAggregatorWeb.Helpers, only: [get_actor: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.LiveView.Socket

  require Logger

  @collection_action_events ~w(
    set_mapping
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
    |> refresh(reload_collection: event == "set_idle_encoding")
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

  defp refresh(socket, refresh_opts \\ []) do
    reload_collection = Keyword.get(refresh_opts, :reload_collection, false)

    %{
      assigns: %{
        collection: %{id: id},
        meta: %{result: %{ash_pagify: ash_pagify, opts: opts}},
        layer: layer
      }
    } =
      socket

    opts = maybe_put_tsvector(layer, opts)
    opts = Keyword.put(opts, :actor, get_actor(socket))

    case AshPagify.validate_and_run(Record, ash_pagify, opts, id) do
      {:ok, {records, meta}} ->
        %{meta: origin_meta, results: origin_results} = socket.assigns

        socket =
          socket
          |> assign(:meta, AsyncResult.ok(origin_meta, meta))
          |> assign(:results, AsyncResult.ok(origin_results, :results))
          |> stream(:results, records, reset: true)
          |> maybe_reload_collection(reload_collection)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/records")}
    end
  end

  defp maybe_reload_collection(socket, true) do
    assign(
      socket,
      :collection,
      get_collection_full(socket.assigns.collection.id, get_actor(socket))
    )
  end

  defp maybe_reload_collection(socket, _), do: socket

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
