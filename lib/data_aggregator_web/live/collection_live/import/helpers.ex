defmodule DataAggregatorWeb.CollectionLive.Import.Helpers do
  @moduledoc """
  This module contains helper functions for the collection > import live view.
  """

  alias DataAggregator.DarwinCore.Schema

  def load do
    [
      :duration,
      :collection_name,
      :missing_mappings,
      :attachment_filename,
      :attachment_byte_size,
      :created_by,
      :started_by,
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

  @doc """
  Returns a map of fields that are not mappable in the import mapping process
  With the key being the prefixed attribute name and the value being the original attribute name.
  """
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

          name = maybe_suffix_required(name, not attribute.allow_nil?)

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

  defp maybe_suffix_required(name, true), do: "#{name} (required)"
  defp maybe_suffix_required(name, false), do: name

  def invalid?(nil), do: false
  def invalid?(import), do: not Enum.empty?(import.missing_mappings)

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
