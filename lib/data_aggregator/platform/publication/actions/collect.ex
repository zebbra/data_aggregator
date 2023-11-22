defmodule DataAggregator.Platform.Publication.Actions.CollectRecords do
  @moduledoc """
  Custom action to collect the records according to a set of rules
  """
  use Ash.Resource.Actions.Implementation

  require Ash.Query

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  @impl true
  def run(input, _opts, _context) do
    consumer = input.arguments.consumer

    case consumer.publication_type do
      :gbif -> gbif_filter() |> Records.read()
      :dissco -> dissco_filter() |> Records.read()
      _ -> {:error, "Invalid publication type"}
    end
  end

  defp gbif_filter do
    Record
    |> Ash.Query.filter(
      not is_nil(tax_kingdom) and
        not is_nil(tax_taxon_id) and
        not is_nil(tax_scientific_name) and
        not is_nil(mte_material_entity_id)
    )
  end

  defp dissco_filter do
    Record
    |> Ash.Query.filter(
      not is_nil(tax_kingdom) and
        not is_nil(tax_taxon_id) and
        not is_nil(tax_scientific_name) and
        not is_nil(mte_material_entity_id)
    )
  end
end
