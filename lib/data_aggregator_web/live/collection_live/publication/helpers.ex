defmodule DataAggregatorWeb.CollectionLive.Publication.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > publication live view.
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
        :publication_progress
      ]
  end

  def can_run?(nil), do: false
  def can_run?(publication), do: publication.state in [:pending]

  def can_delete?(nil), do: false
  def can_delete?(publication), do: publication.state in [:pending, :done, :failed]
end
