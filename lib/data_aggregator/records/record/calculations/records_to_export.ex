defmodule DataAggregator.Records.Export.Calculations.RecordsToExport do
  @moduledoc """
  This `Ash.Calculation` calculates the records for exporting the collection and returns an `Ash.Query`.
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

  defp map_restriction(%Collection{id: id}), do: default_restriction(id)

  defp default_restriction(id) do
    # customize this to restrict the records to be exported
    # Record
    # |> Ash.Query.load(collection: [:id])
    # |> Ash.Query.filter(
    #   collection.id == ^id and
    #     not is_nil(tax_kingdom) and
    #     not is_nil(tax_taxon_id) and
    #     not is_nil(tax_scientific_name) and
    #     not is_nil(mte_material_entity_id)
    # )

    all_records_query(id)
  end

  # use this if we do not want to restrict the records to be exported
  defp all_records_query(id) do
    Record
    |> Ash.Query.load(collection: [:id])
    |> Ash.Query.filter(collection.id == ^id)
  end
end
