defmodule DataAggregator.Records.Calculations.RecordsToExport do
  @moduledoc """
  This `Ash.Calculation` calculates the records for exporting the collection and returns an `Ash.Query`.
  """

  use Ash.Calculation

  alias DataAggregator.Records.Collection

  require Ash.Query
  require Logger

  @impl Ash.Calculation
  def calculate(collections, _opts, _ctx) do
    Enum.map(collections, &map_restriction(&1))
  end

  defp map_restriction(%Collection{id: id}), do: restriction(id)

  # use this if we do not want to restrict the records to be exported
  defp restriction(id) do
    %{
      collection: %{id: %{eq: id}}
    }
  end
end
