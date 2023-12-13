defmodule DataAggregator.Records.Export.Calculations.RecordsToPublish do
  @moduledoc """
  This `Ash.Calculation` calculates the records for publishing the collection and returns an `Ash.Query`.
  """

  use Ash.Calculation

  require Logger
  require Ash.Query

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @impl Ash.Calculation
  def calculate(collections, _opts, _ctx) do
    Enum.map(collections, &map_reviewer(&1))
  end

  defp map_reviewer(%Collection{reviewer: nil, id: id}), do: all_records_query(id)

  defp map_reviewer(%Collection{reviewer: reviewer, id: id}) do
    case reviewer do
      :swiss_bryophytes -> default_restriction(id)
      :swiss_lichens -> default_restriction(id)
      :swiss_fungi -> default_restriction(id)
      :info_fauna -> default_restriction(id)
      :info_flora -> default_restriction(id)
      :cco_kof -> default_restriction(id)
      :ornithology -> default_restriction(id)
      _ -> {:error, "invalid :reviewer configured on collection"}
    end
  end

  defp default_restriction(id) do
    Record
    |> Ash.Query.load(collection: [:id])
    |> Ash.Query.filter(
      collection.id == ^id and
        not is_nil(tax_kingdom) and
        not is_nil(tax_taxon_id) and
        not is_nil(tax_scientific_name) and
        not is_nil(mte_material_entity_id)
    )
  end

  defp all_records_query(id) do
    Record
    |> Ash.Query.load(collection: [:id])
    |> Ash.Query.filter(collection.id == ^id)
  end
end
