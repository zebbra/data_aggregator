defmodule DataAggregatorWeb.RecordLive.Helpers do
  @moduledoc """
  Helper functions for the RecordLive module.
  """

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Record

  def attrs_by_category_in_layers(record) do
    for category <- Schema.categories() do
      attributes =
        for dwc_attribute <- category.dwc_attributes do
          attribute = dwc_attribute.attribute

          %{
            name: attribute.name,
            imported:
              imported_attribute(
                record,
                String.to_existing_atom("#{category.name}_#{attribute.name}")
              ),
            encoded:
              encoded_attribute(
                record,
                String.to_existing_atom("#{category.name}_#{attribute.name}")
              )
          }
        end

      %{label: category.label, description: category.description, attributes: attributes}
    end
  end

  @spec imported_attribute(Record.t(), atom()) :: any()
  def imported_attribute(record, attribute) do
    if record != nil do
      record |> Map.get(attribute) |> value_for_record_attribute()
    else
      "-"
    end
  end

  @spec encoded_attribute(Record.t(), atom(), String.t() | nil) :: any()
  def encoded_attribute(record, attribute, layer \\ nil)
  def encoded_attribute(record, attribute, "original"), do: Map.get(record, attribute)

  def encoded_attribute(record, attribute, _) do
    if record.encoded_record != nil do
      record.encoded_record |> Map.get(attribute) |> value_for_record_attribute()
    else
      Map.get(record, attribute)
    end
  end

  defp value_for_record_attribute(value) when is_nil(value), do: "-"
  defp value_for_record_attribute(value) when value === "", do: "-"
  defp value_for_record_attribute(value), do: value
end
