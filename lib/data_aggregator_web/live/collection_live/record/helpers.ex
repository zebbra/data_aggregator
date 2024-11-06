defmodule DataAggregatorWeb.CollectionLive.Record.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > record live view.
  """

  use DataAggregatorWeb, :verified_routes

  import AshPagify.Components, only: [build_path: 2, build_scope_path: 3]

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Record

  @transformers Schema.dwc_transformers()

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

  def attrs_by_category_in_layers(record) do
    for category <- Schema.categories() do
      attributes =
        for dwc_attribute <- category.dwc_attributes do
          attribute = String.to_existing_atom("#{category.name}_#{dwc_attribute.attribute.name}")

          %{
            name: dwc_attribute.dwc_field || dwc_attribute.attribute.name,
            imported:
              record
              |> imported_attribute(attribute)
              |> maybe_transform_value(attribute),
            encoded:
              record
              |> encoded_attribute(attribute)
              |> maybe_transform_value(attribute)
          }
        end

      %{label: category.label, description: category.description, attributes: attributes}
    end
  end

  defp maybe_transform_value(value, attribute_name) do
    case @transformers[attribute_name] do
      nil -> value
      transformer -> transformer.(value)
    end
  end

  @spec imported_attribute(Record.t(), atom()) :: any()
  def imported_attribute(record, attribute) do
    if record == nil do
      "-"
    else
      record |> Map.get(attribute) |> value_for_record_attribute()
    end
  end

  @spec encoded_attribute(Record.t(), atom(), String.t() | nil) :: any()
  def encoded_attribute(record, attribute, layer \\ nil)
  def encoded_attribute(record, attribute, "import"), do: Map.get(record, attribute)

  def encoded_attribute(record, attribute, _) do
    if record.encoded_record == nil do
      Map.get(record, attribute)
    else
      record.encoded_record |> Map.get(attribute) |> value_for_record_attribute()
    end
  end

  def get_dwc_field("fast_track_status"), do: "publicationStatus"
  def get_dwc_field("approval_status"), do: "approvalStatus"

  def get_dwc_field(prefixed_attribute_name) do
    Schema.dwc_field_from_prefixed_attribute_name(prefixed_attribute_name)
  end

  defp value_for_record_attribute(value) when is_nil(value), do: "-"
  defp value_for_record_attribute(value) when value === "", do: "-"
  defp value_for_record_attribute(value), do: value
end
