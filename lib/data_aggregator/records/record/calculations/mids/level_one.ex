defmodule DataAggregator.Records.Record.Calculations.Mids.LevelOne do
  @moduledoc """
    Calculation for MIDS level one to indicate if a record fulfills the requirements for MIDS level one.
  """
  use Ash.Resource.Calculation

  import Ash.Expr

  @impl true
  def load(_query, _opts, _context) do
    []
  end

  @impl true
  def expression(_opts, _context) do
    expr(
      not is_nil(encoded_record.mte_catalog_number) and
        not is_nil(encoded_record.tax_scientific_name) and
        not is_nil(encoded_record.oth_institution_code)
    )
  end
end
