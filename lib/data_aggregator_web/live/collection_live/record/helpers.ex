defmodule DataAggregatorWeb.CollectionLive.Record.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > record live view.
  """

  use DataAggregatorWeb, :verified_routes

  import AshPagify.Components, only: [build_path: 2, build_scope_path: 3]

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  @transformers Schema.dwc_transformers()
  @fields_not_shown_in_ui [
    :loc_decimal_presence,
    :loc_swiss_coordinates_95_presence,
    :loc_swiss_coordinates_03_presence,
    :eve_event_date_presence
  ]

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

  def path_helper(collection, "encoding", meta, nil) do
    build_path(~p"/datasets/#{collection}/records?", meta)
  end

  def path_helper(collection, layer, meta, nil) do
    build_path(~p"/datasets/#{collection}/records?layer=#{layer}", meta)
  end

  def path_helper(collection, "encoding", meta, scope) do
    build_scope_path(~p"/datasets/#{collection}/records", meta, scope)
  end

  def path_helper(collection, layer, meta, scope) do
    build_scope_path(~p"/datasets/#{collection}/records?layer=#{layer}", meta, scope)
  end

  def attrs_by_category(record, collection) do
    record = Ash.load!(record, :encoded_record, lazy?: true)
    output_dwc_fields = Catalog.get_all_output_dwc_attributes()

    collection_attributes =
      Schema.collection_attributes()
      |> Enum.map(fn attribute ->
        %{
          name: attribute.dwc_field,
          category_name: "oth",
          imported: Map.get(collection, attribute.collection_field),
          encoded: "-"
        }
      end)
      |> Enum.filter(fn %{imported: value} -> value not in ["", nil] end)

    Schema.prefixed_attribute_names()
    |> Enum.filter(&should_show_attribute?(&1, record, output_dwc_fields))
    |> Enum.map(fn key ->
      imported_value =
        record
        |> Map.get(key)
        |> maybe_transform_value(key)

      encoded_value =
        record.encoded_record
        |> Map.get(key)
        |> maybe_transform_value(key)

      encoded_value =
        if encoded_value == imported_value and not Enum.member?(output_dwc_fields, key) do
          "-"
        else
          encoded_value
        end

      %{
        name: get_dwc_field(key),
        category_name: key |> Atom.to_string() |> String.split("_") |> List.first(),
        imported: imported_value,
        encoded: encoded_value
      }
    end)
    |> Enum.concat(collection_attributes)
    |> by_category()
  end

  defp should_show_attribute?(key, record, output_dwc_fields) do
    cond do
      key in @fields_not_shown_in_ui ->
        false

      Map.get(record, key) not in ["", nil] ->
        true

      Enum.member?(output_dwc_fields, key) and
          Map.get(record.encoded_record, key) not in ["", nil] ->
        true

      true ->
        false
    end
  end

  defp maybe_transform_value(value, key) do
    if @transformers[key] do
      value |> @transformers[key].() |> escape_nil()
    else
      escape_nil(value)
    end
  end

  defp escape_nil(value) when value in [nil, ""], do: "-"
  defp escape_nil(value), do: value

  defp by_category(changes) do
    grouped = Enum.group_by(changes, &Map.get(&1, :category_name), & &1)

    category_names =
      changes
      |> Enum.map(fn %{category_name: category_name} -> category_name end)
      |> Enum.uniq()

    Schema.categories()
    |> Enum.filter(fn category -> Enum.member?(category_names, Atom.to_string(category.name)) end)
    |> Enum.map(fn category ->
      %{
        label: category.label,
        description: category.description,
        attributes: Enum.sort_by(grouped[Atom.to_string(category.name)], &Map.get(&1, :name))
      }
    end)
  end

  def checked_publication_query(publication_query, "import" = _layer) do
    AshPagify.merge_filters(%AshPagify{filters: publication_query}, %{
      or: [
        %{loc_country: %{is_nil: false}},
        %{
          and: [
            %{
              or: [
                %{loc_decimal_latitude: %{is_nil: true}},
                %{loc_decimal_longitude: %{is_nil: true}}
              ]
            },
            %{
              or: [
                %{loc_swiss_coordinates_lv95_y: %{is_nil: true}},
                %{loc_swiss_coordinates_lv95_x: %{is_nil: true}}
              ]
            },
            %{
              or: [
                %{loc_swiss_coordinates_lv03_y: %{is_nil: true}},
                %{loc_swiss_coordinates_lv03_x: %{is_nil: true}}
              ]
            }
          ]
        }
      ]
    }).filters
  end

  def checked_publication_query(publication_query, _layer) do
    AshPagify.merge_filters(%AshPagify{filters: publication_query}, %{
      or: [
        %{encoded_record: %{loc_country: %{is_nil: false}}},
        %{
          and: [
            %{
              or: [
                %{encoded_record: %{loc_decimal_latitude: %{is_nil: true}}},
                %{encoded_record: %{loc_decimal_longitude: %{is_nil: true}}}
              ]
            },
            %{
              or: [
                %{encoded_record: %{loc_swiss_coordinates_lv95_y: %{is_nil: true}}},
                %{encoded_record: %{loc_swiss_coordinates_lv95_x: %{is_nil: true}}}
              ]
            },
            %{
              or: [
                %{encoded_record: %{loc_swiss_coordinates_lv03_y: %{is_nil: true}}},
                %{encoded_record: %{loc_swiss_coordinates_lv03_x: %{is_nil: true}}}
              ]
            }
          ]
        }
      ]
    }).filters
  end

  def publication_rules_query(publication_query) do
    AshPagify.merge_filters(%AshPagify{filters: publication_query}, %{
      and: [
        %{encoded_record: %{swiss_species: %{center: %{is_nil: false}}}},
        %{encoded_record: %{loc_country: %{eq: "Switzerland"}}}
      ]
    }).filters
  end

  def count_from_query(query, collection) do
    Record
    |> AshPagify.query_for_filters_map(query)
    |> Ash.Query.set_tenant(collection)
    |> Ash.count!()
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

  def get_dwc_field("publication_status"), do: "publicationStatus"
  def get_dwc_field("validation_status"), do: "validationStatus"

  def get_dwc_field(prefixed_attribute_name) do
    Schema.dwc_field_from_prefixed_attribute_name(prefixed_attribute_name)
  end

  defp value_for_record_attribute(value) when is_nil(value), do: "-"
  defp value_for_record_attribute(value) when value === "", do: "-"
  defp value_for_record_attribute(value), do: value
end
