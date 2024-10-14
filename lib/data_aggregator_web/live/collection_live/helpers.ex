defmodule DataAggregatorWeb.CollectionLive.Helpers do
  @moduledoc """
  This module contains helper functions for the collection live view.
  """

  alias DataAggregator.Records.Collection

  def load do
    [
      :digitizing_progress,
      :importing,
      :exporting,
      :encoding,
      :publishing,
      :approving,
      :busy
    ]
  end

  @load_light [
    :importing,
    :exporting,
    :encoding,
    :publishing,
    :approving,
    :busy
  ]

  @load_full @load_light ++
               [
                 :records_count_not_encoded,
                 :records_count_not_published,
                 :records_count_not_approved
               ]

  def get_collection_light(id, actor) do
    Collection.get_by_id!(id, load: @load_light, actor: actor)
  end

  def get_collection_full(id, actor) do
    Collection.get_by_id!(id, load: @load_full, actor: actor)
  end

  def busy_action("set_importing"), do: "dataset:import"
  def busy_action(%{importing: true}), do: "dataset:import"
  def busy_action("set_exporting"), do: "collection:export"
  def busy_action(%{exporting: true}), do: "collection:export"
  def busy_action("set_encoding"), do: "encode:toggle"
  def busy_action(%{encoding: true}), do: "encode:toggle"
  def busy_action("set_fast_track_publishing"), do: "fast_track_pub:toggle"
  def busy_action(%{publishing: true}), do: "fast_track_pub:toggle"
  def busy_action("set_approving"), do: "approval_pub:toggle"
  def busy_action(%{approving: true}), do: "approval_pub:toggle"
  def busy_action(_), do: nil
end
