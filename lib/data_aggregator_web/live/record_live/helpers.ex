defmodule DataAggregatorWeb.RecordLive.Helpers do
  @moduledoc """
  Helper functions for the RecordLive module.
  """

  alias DataAggregator.DarwinCore.Schema

  import DataAggregatorWeb.Helpers, only: [imported_attribute: 2, encoded_attribute: 2]

  def attrs_by_category_in_layers(record) do
    for category <- Schema.categories() do
      attributes =
        for attribute <- category.attributes do
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
end
