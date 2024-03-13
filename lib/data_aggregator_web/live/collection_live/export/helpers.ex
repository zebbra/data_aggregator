defmodule DataAggregatorWeb.CollectionLive.Export.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > export live view.
  """

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias Phoenix.LiveView.Socket

  require Logger

  def subscribe_for_export_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection do
      topic = [
        "export:#{id}:created",
        "export:#{id}:updated",
        "export:#{id}:destroyed"
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

  def can_run?(export) do
    export.state in [:pending]
  end

  def current_step(action) do
    case action do
      :new -> 1
      :edit -> 2
      :summary -> 3
    end
  end
end
