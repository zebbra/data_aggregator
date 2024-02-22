defmodule DataAggregator.Records.Import.Calculations.Mappings do
  @moduledoc """
  This `Ash.Calculation` calculates the mappings.
  """

  use Ash.Calculation

  alias DataAggregator.Records.Import

  require Logger

  @impl Ash.Calculation
  def calculate(imports, opts, ctx) do
    Enum.map(imports, &mappings(&1, opts, ctx))
  end

  defp mappings(%Import{columns: nil}, _opts, _context), do: []

  defp mappings(%Import{columns: columns}, _opts, _context) do
    columns
    |> DataAggregator.Records.load!([:mapped?], lazy?: true)
    |> Enum.filter(& &1.mapped?)
  end
end
