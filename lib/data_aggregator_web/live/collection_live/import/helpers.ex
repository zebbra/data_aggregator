defmodule DataAggregatorWeb.CollectionLive.Import.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > import live view.
  """

  alias DataAggregator.Records.Import

  def collection_scope(params) do
    Import |> Ash.Query.filter_input(%{"collection" => %{"id" => params["id"]}})
  end

  def can_run?(import) do
    cond do
      length(import.missing_mappings) > 0 -> false
      import.state in [:pending] -> true
      true -> false
    end
  end

  def current_step(action) do
    case action do
      :new -> 1
      :edit -> 2
      :summary -> 3
    end
  end
end
