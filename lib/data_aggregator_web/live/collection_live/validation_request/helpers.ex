defmodule DataAggregatorWeb.CollectionLive.ValidationRequest.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > validation_request live view.
  """

  def load do
    [
      :duration,
      :attachment_filename,
      :attachment_byte_size,
      :started_by,
      attachment: [:filename, :url, :byte_size]
    ]
  end

  def load_all do
    load() ++
      [
        :validation_request_progress
      ]
  end

  def can_run?(nil), do: false
  def can_run?(validation_request), do: validation_request.state in [:pending]

  def can_delete?(nil), do: false
  def can_delete?(validation_request), do: validation_request.state in [:pending, :done, :failed]
end
