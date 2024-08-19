defmodule DataAggregatorWeb.CollectionLive.Export.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > export live view.
  """

  def load do
    [
      :duration,
      :attachment_filename,
      :attachment_byte_size,
      attachment: [:filename, :url, :byte_size]
    ]
  end

  def load_all do
    load() ++
      [
        :export_progress
      ]
  end

  def can_run?(nil), do: false
  def can_run?(export), do: export.state in [:pending]

  def can_delete?(nil), do: false
  def can_delete?(export), do: export.state in [:pending, :exported, :failed]
end
