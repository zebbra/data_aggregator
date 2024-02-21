defmodule DataAggregator.Records.Import.Calculations.Mappings do
  @moduledoc """
  This `Ash.Calculation` calculates the mappings.
  """

  use Ash.Calculation

  require Logger

  alias DataAggregator.DarwinCore.Schema.Category
  alias DataAggregator.Records.Import

  @impl Ash.Calculation
  def calculate(imports, opts, ctx) do
    imports
    |> DataAggregator.Records.load!([:missing_mappings], lazy?: true)
    |> Enum.map(&mappings(&1, opts, ctx))
  end

  defp mappings(%Import{columns: nil}, _opts, _context), do: []

  defp mappings(%Import{columns: columns, missing_mappings: missing_mappings}, _opts, _context) do
    missing_mandatory_mapping_columns =
      missing_mappings
      |> Enum.flat_map(&Category.prefixed_attributes/1)
      |> Enum.map(&attribute_to_column/1)

    columns =
      columns
      |> DataAggregator.Records.load!([:mapped?], lazy?: true)
      |> Enum.filter(& &1.mapped?)

    columns ++ missing_mandatory_mapping_columns
  end

  defp attribute_to_column(%Ash.Resource.Attribute{} = attribute) do
    %Import.Column{
      name: nil,
      type: attribute.type,
      mapped_to: Atom.to_string(attribute.name)
    }
  end
end
