defmodule DataAggregatorWeb.RecordLive.Helpers do
  @moduledoc """
  Helper functions for the RecordLive module.
  """

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Record

  @transformers Schema.dwc_transformers()

  def attrs_by_category_in_layers(record) do
    for category <- Schema.categories() do
      attributes =
        for dwc_attribute <- category.dwc_attributes do
          attribute = String.to_existing_atom("#{category.name}_#{dwc_attribute.attribute.name}")

          %{
            name: dwc_attribute.dwc_field,
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
  def encoded_attribute(record, attribute, "original"), do: Map.get(record, attribute)

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
