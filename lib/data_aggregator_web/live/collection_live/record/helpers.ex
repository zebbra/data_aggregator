defmodule DataAggregatorWeb.CollectionLive.Record.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > record live view.
  """

  use DataAggregatorWeb, :verified_routes

  import AshPagify.Components, only: [build_path: 2, build_scope_path: 3]

  alias DataAggregator.Records.Record

  def busy?(action, busy_action), do: action == busy_action

  def filter_map(ash_pagify, query, layer) do
    opts = maybe_put_tsvector(layer)

    Record
    |> AshPagify.query_to_filters_map(ash_pagify, opts)
    |> AshPagify.merge_filters(query)
    |> Map.get(:filters)
  end

  def maybe_put_tsvector(layer, opts \\ [])
  def maybe_put_tsvector("import", opts), do: opts

  def maybe_put_tsvector(_, opts) do
    AshPagify.set_tsvector(:encoded_tsvector, opts)
  end

  def path_helper(collection, layer, meta, scope \\ nil)

  def path_helper(collection, "approval", meta, nil) do
    build_path(~p"/collections/#{collection}/records", meta)
  end

  def path_helper(collection, layer, meta, nil) do
    build_path(~p"/collections/#{collection}/records?layer=#{layer}", meta)
  end

  def path_helper(collection, "approval", meta, scope) do
    build_scope_path(~p"/collections/#{collection}/records", meta, scope)
  end

  def path_helper(collection, layer, meta, scope) do
    build_scope_path(~p"/collections/#{collection}/records?layer=#{layer}", meta, scope)
  end

  def attributes_with_data(attributes) do
    Enum.filter(attributes, fn %{name: _, imported: imported, encoded: encoded} ->
      imported != "-" || encoded != "-"
    end)
  end

  def category_has_data?(category) do
    Enum.any?(category.attributes, fn %{imported: imported, encoded: encoded} ->
      imported != "-" || encoded != "-"
    end)
  end
end
