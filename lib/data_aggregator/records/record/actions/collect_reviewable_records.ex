defmodule DataAggregator.Records.Actions.CollectReviewableRecords do
  @moduledoc """
  Filter the Records of a collection to only those that are reviewable for the configured reviewer.
  """
  use Ash.Resource.Actions.Implementation
  require Ash.Query

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  @impl true
  def run(input, _opts, _context) do
    collection = input.arguments.collection

    case collection.reviewer do
      :swiss_bryophytes -> default_restriction(collection)
      :swiss_lichens -> default_restriction(collection)
      :swiss_fungi -> default_restriction(collection)
      :info_fauna -> default_restriction(collection)
      :info_flora -> default_restriction(collection)
      :cco_kof -> default_restriction(collection)
      :ornithology -> default_restriction(collection)
      _ -> {:error, "invalid :reviewer configured on collection or no reviewer "}
    end
  end

  defp default_restriction(%{id: id}) do
    Record
    |> Ash.Query.load(collection: [:id])
    |> Ash.Query.filter(
      collection.id == ^id and
        not is_nil(tax_kingdom) and
        not is_nil(tax_taxon_id) and
        not is_nil(tax_scientific_name) and
        not is_nil(mte_material_entity_id)
    )
    |> Records.read()
  end
end
