defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > image upload live view.
  """

  alias DataAggregator.DarwinCore.Schema

  def load do
    [
      :created_by,
      :started_by,
      upload_log: [:filename, :url, :byte_size],
      attachment: [:filename, :url, :byte_size]
    ]
  end

  def load_all, do: load()

  def not_mappable_fields do
    %{
      oth_gbif_id: :gbif_id
    }
  end

  @doc """
  Returns the attributes as options for a select input grouped by category.
  """
  @spec attribute_options() :: [{String.t(), [{String.t(), String.t()}]}]
  def attribute_options do
    for category <- Schema.categories() do
      filtered_attributes =
        Enum.reject(category.dwc_attributes, fn dwc_attribute ->
          not_mappable_fields = Map.values(not_mappable_fields())
          dwc_attribute.attribute.name in not_mappable_fields
        end)

      options =
        for dwc_attribute <- filtered_attributes do
          attribute = dwc_attribute.attribute

          name =
            if is_nil(dwc_attribute.dwc_field) do
              Atom.to_string(attribute.name)
            else
              dwc_attribute.dwc_field
            end

          value = Schema.Category.prefixed_attribute_name(category, attribute)

          {name, value}
        end

      category_label =
        case Schema.category_label_by_description(category.description) do
          nil -> category.description
          label -> "#{label}: #{category.description}"
        end

      {category_label, options}
    end
  end
end
