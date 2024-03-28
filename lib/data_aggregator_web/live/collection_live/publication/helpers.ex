defmodule DataAggregatorWeb.CollectionLive.Publication.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > publication live view.
  """

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias Phoenix.LiveView.Socket

  require Logger

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

  def can_run?(publication) do
    publication.state in [:pending]
  end

  def current_step(action) do
    case action do
      :new -> 1
      :edit -> 2
      :summary -> 3
    end
  end
end
