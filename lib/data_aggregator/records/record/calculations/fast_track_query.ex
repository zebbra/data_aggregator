defmodule DataAggregator.Records.Calculations.FastTrackQuery do
  @moduledoc """
  This `Ash.Calculation` calculates the records used for fast track publication of a collection and returns an `Ash.Query`.
  """

  use Ash.Calculation

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @impl Ash.Calculation
  def calculate(collections, _opts, _ctx) do
    Enum.map(collections, &map_restriction(&1))
  end

  defp map_restriction(%Collection{id: id}), do: restriction(id)

  defp restriction(id) do
    # TODO: customize to restrict the records to be published
    Record
    |> Ash.Query.load(collection: [:id], encoded_record: [:id])
    |> Ash.Query.filter(
      collection.id == ^id and
        not is_nil(encoded_record.tax_kingdom)
    )
  end
end
