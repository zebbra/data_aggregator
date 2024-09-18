defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > image upload live view.
  """

  def load do
    [
      attachment: [:filename, :url, :byte_size]
    ]
  end
end
