defmodule DataAggregatorWeb.CollectionLive.Helpers do
  @moduledoc """
  This module contains helper functions for the collection live view.
  """

  alias DataAggregator.Records.Collection

  def get_collection(id) do
    Collection.get_by_id!(id,
      load: [
        :records_count,
        :digitizing_progress,
        :encoding_state,
        :records_count_not_encoded,
        :records_count_failed,
        :imports_count_running,
        :exports_count_running,
        :records_count_encoding,
        :records_count_publishing,
        :records_count_approving,
        :importing,
        :exporting,
        :encoding,
        :publishing,
        :approving,
        :busy
      ]
    )
  end

  def busy_action(collection) do
    cond do
      collection.importing -> "dataset:import"
      collection.exporting -> "collection:export"
      collection.encoding -> "collection:encode"
      collection.publishing -> "collection:fast_track_pub"
      collection.approving -> "collection:approval_pub"
      true -> nil
    end
  end
end
