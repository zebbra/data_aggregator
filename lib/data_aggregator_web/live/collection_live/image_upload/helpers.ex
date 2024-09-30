defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > image upload live view.
  """

  def load do
    [
      :mapped_images,
      :unmapped_images,
      attachment: [:filename, :url, :byte_size]
    ]
  end

  def load_all do
    load() ++
      []
  end
end
