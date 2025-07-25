defmodule DataAggregator.Records.Calculations.ValidationQuery do
  @moduledoc """
  This `Ash.Resource.Calculation` calculates the records used for validation publication of a collection and returns an `Ash.Query`.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.Records.Collection

  require Ash.Query
  require Logger

  @impl Ash.Resource.Calculation
  def calculate(collections, _opts, _ctx) do
    Enum.map(collections, &map_restriction(&1))
  end

  defp map_restriction(%Collection{id: id}), do: restriction(id)

  defp restriction(id) do
    # TODO: customize to restrict the records to be published
    %{
      collection: %{id: %{eq: id}}
    }
  end
end
