defmodule DataAggregatorWeb.CollectionLive.Record.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > record live view.
  """
  alias DataAggregator.Records.Record

  def busy?(action, busy_action), do: action == busy_action

  def filter_map(pagify, query, layer) do
    opts = maybe_put_tsvector(layer)

    Record
    |> Pagify.query_to_filters_map(pagify, opts)
    |> Pagify.merge_filters(query)
    |> Map.get(:filters)
  end

  def maybe_put_tsvector(layer, opts \\ [])
  def maybe_put_tsvector("import", opts), do: opts

  def maybe_put_tsvector(_, opts) do
    Pagify.set_tsvector(:encoded_tsvector, opts)
  end
end
