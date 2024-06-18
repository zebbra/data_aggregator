defmodule DataAggregatorWeb.CollectionLive.Helpers do
  @moduledoc """
  This module contains helper functions for the collection live view.
  """

  alias DataAggregator.Records.Collection

  def load do
    [
      :records_count,
      :digitizing_progress,
      :records_count_not_encoded,
      :importing,
      :exporting,
      :encoding,
      :publishing,
      :approving,
      :busy
    ]
  end

  def get_collection(id) do
    Collection.get_by_id!(id,
      load: [
        :records_count,
        :digitizing_progress,
        :records_count_not_encoded,
        :importing,
        :exporting,
        :encoding,
        :publishing,
        :approving,
        :busy
      ]
    )
  end

  def busy_action("set_importing"), do: "dataset:import"
  def busy_action(%{importing: true}), do: "dataset:import"
  def busy_action("set_exporting"), do: "collection:export"
  def busy_action(%{exporting: true}), do: "collection:export"
  def busy_action("set_encoding"), do: "collection:encode"
  def busy_action(%{encoding: true}), do: "collection:encode"
  def busy_action("set_fast_track_publishing"), do: "collection:fast_track_pub"
  def busy_action(%{publishing: true}), do: "collection:fast_track_pub"
  def busy_action("set_approving"), do: "collection:approval_pub"
  def busy_action(%{approving: true}), do: "collection:approval_pub"
  def busy_action(_), do: nil
end
