defmodule DataAggregatorWeb.CollectionLive.Import.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > import live view.
  """

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias Phoenix.LiveView.Socket

  require Logger

  def subscribe_for_import_updates(socket, connected) do
    with true <- connected,
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection,
         topic <- [
           "import:#{id}:created",
           "import:#{id}:updated",
           "import:#{id}:destroyed"
         ] do
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

  def can_run?(import) do
    cond do
      length(import.missing_mappings) > 0 -> false
      import.state in [:pending] -> true
      true -> false
    end
  end

  def current_step(action) do
    case action do
      :new -> 1
      :edit -> 2
      :summary -> 3
    end
  end
end
