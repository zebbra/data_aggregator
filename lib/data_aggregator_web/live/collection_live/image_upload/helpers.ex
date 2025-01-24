defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > image upload live view.
  """

  def load do
    [
      :mapped_images,
      :unmapped_images,
      :mapped_images_count,
      :unmapped_images_count,
      :invalid_files_count,
      :created_by,
      :started_by,
      upload_log: [:filename, :url, :byte_size],
      attachment: [:filename, :url, :byte_size]
    ]
  end

  def load_all, do: load()
end
