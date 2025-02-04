defmodule DataAggregatorWeb.CollectionLive.Record.Subscriptions do
  @moduledoc """
  This module contains helper functions for the collection > record subscriptions.
  """

  use Phoenix.LiveView
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import Ash.Expr
  import DataAggregatorWeb.CollectionLive.Helpers
  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [maybe_put_tsvector: 2]
  import DataAggregatorWeb.Helpers, only: [get_actor: 1, get_tenant: 1]

  alias Ash.Notifier.Notification
  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.LiveView.Socket

  require Ash.Query
  require Logger

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
    opts = Keyword.put(opts, :tenant, get_tenant(socket))

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
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/records")}
    end
  end

  defp maybe_reload_collection(socket, true) do
    %{collection: collection} = socket.assigns

    count_not_encoded =
      Record
      |> Ash.Query.set_tenant(collection)
      |> Ash.Query.filter(expr(not_encoded == true))
      |> Ash.count!()

    count_not_published =
      Record
      |> Ash.Query.set_tenant(collection)
      |> Ash.Query.filter(expr(not_published == true))
      |> Ash.count!()

    count_not_validated =
      Record
      |> Ash.Query.set_tenant(collection)
      |> Ash.Query.filter(expr(not_validated == true))
      |> Ash.count!()

    %{
      records_count_not_validated: origin_records_count_not_validated,
      records_count_not_encoded: origin_records_count_not_encoded,
      records_count_not_published: origin_records_count_not_published
    } = socket.assigns

    socket
    |> assign(:collection, collection)
    |> assign(
      :records_count_not_validated,
      AsyncResult.ok(origin_records_count_not_validated, count_not_validated)
    )
    |> assign(
      :records_count_not_encoded,
      AsyncResult.ok(origin_records_count_not_encoded, count_not_encoded)
    )
    |> assign(
      :records_count_not_published,
      AsyncResult.ok(origin_records_count_not_published, count_not_published)
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
