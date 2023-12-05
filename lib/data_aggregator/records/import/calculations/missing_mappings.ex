defmodule DataAggregator.Records.Import.Calculations.MissingMappings do
  @moduledoc """
  This `Ash.Calculation` calculates the missing column mappings based on the required attributes
  using the attribute definitions from `DataAggregator.DarwinCore.Schema`.
  """

  use Ash.Calculation

  require Logger

  alias Ash.Resource.Attribute
  alias DataAggregator.DarwinCore
  alias DataAggregator.DarwinCore.Schema.Category
  alias DataAggregator.Records.Import

  @impl Ash.Calculation
  def calculate(imports, opts, ctx) do
    Enum.map(imports, &missing_mappings(&1, opts, ctx))
  end

  defp missing_mappings(%Import{columns: columns}, _opts, _context) do
    existing_mappings = Enum.map(columns, & &1.mapped_to)

    categories = DarwinCore.Schema.categories()

    missing_attribute? = fn
      category, %Attribute{allow_nil?: false} = attr ->
        prefixed_name = Category.prefixed_attribute_name(category, attr)
        !Enum.member?(existing_mappings, to_string(prefixed_name))

      _category, %Attribute{allow_nil?: true} ->
        false
    end

    filter_missing_attributes = fn category ->
      %Category{attributes: attributes} = category
      missing_attributes = Enum.filter(attributes, &missing_attribute?.(category, &1))
      %Category{category | attributes: missing_attributes}
    end

    empty_category? = fn
      %Category{attributes: []} -> true
      %Category{} -> false
    end

    categories
    |> Enum.map(filter_missing_attributes)
    |> Enum.reject(empty_category?)
  end
end
