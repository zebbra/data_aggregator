defmodule DataAggregator.Records.Record.Calculations.Mids.LevelTwo do
  @moduledoc """
    Calculation for MIDS level two to indicate if a record fulfills the requirements for MIDS level two.
  """
  use Ash.Calculation

  import Ash.Expr

  @impl true
  def load(_query, _opts, _context) do
    [:mids_level_one]
  end

  @impl true
  def expression(_opts, _context) do
    expr(
      mids_level_one and
        ((not is_nil(mte_part_of_organism) or
            not is_nil(encoded_record.mte_part_of_organism)) and
           (not is_nil(tax_taxon_id) or not is_nil(encoded_record.tax_taxon_id)))
    )
  end
end
