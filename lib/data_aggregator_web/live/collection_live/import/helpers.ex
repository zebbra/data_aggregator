defmodule DataAggregatorWeb.CollectionLive.Import.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > import live view.
  """

  def load do
    [
      :duration,
      :collection_name,
      :missing_mappings,
      :attachment_filename,
      :attachment_byte_size,
      attachment: [:filename, :url, :byte_size]
    ]
  end

  def load_all do
    load() ++
      [
        :import_progress,
        :rows_validated_count,
        :rows_invalid_count,
        :validation_progress,
        :mappings,
        :collection,
        error_log: [:filename, :url, :byte_size]
      ]
  end

  def invalid?(nil), do: false
  def invalid?(import), do: length(import.missing_mappings) > 0

  def can_run?(nil), do: false
  def can_run?(import), do: invalid?(import) == false and import.state in [:pending]

  def can_edit?(nil), do: false
  def can_edit?(import), do: import.state in [:pending]

  def can_delete?(nil), do: false
  def can_delete?(import), do: import.state in [:pending, :imported, :failed]

  def current_step(action) do
    case action do
      :new -> 1
      :edit -> 2
      :summary -> 3
    end
  end
end
