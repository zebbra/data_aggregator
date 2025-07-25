defmodule DataAggregator.Records.Import.Calculations.Mappings do
  @moduledoc """
  This `Ash.Resource.Calculation` calculates the mappings.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.DarwinCore.Schema.Category
  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  require Logger

  @impl Ash.Resource.Calculation
  def calculate(imports, _opts, _ctx) do
    imports
    |> Ash.load!([:missing_mappings], lazy?: true)
    |> Enum.map(&mappings(&1))
  end

  defp mappings(%Import{columns: nil}), do: []

  defp mappings(%Import{columns: columns, missing_mappings: missing_mappings}) do
    missing_mandatory_mapping_columns =
      missing_mappings
      |> Enum.flat_map(&Category.prefixed_attributes/1)
      |> Enum.map(&attribute_to_column/1)

    columns =
      columns
      |> Ash.load!([:mapped?], lazy?: true, domain: Records)
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
