defmodule DataAggregator.Records.Record.Calculations.IucnRedlist do
  @moduledoc """
  Calculation for IUCN Redlist to indicate if a record fulfills the requirements for IUCN Redlist.
  """
  use Ash.Calculation

  import Ash.Expr

  @iucn_redlist_categories ["EX", "EW", "RE", "CR(PE)", "CR", "EN"]

  @impl true
  def load(_query, _opts, _context) do
    []
  end

  @impl true
  def expression(_opts, _context) do
    expr(
      cond do
        iucn_redlist_category in @iucn_redlist_categories -> true
        encoded_record.iucn_redlist_category in @iucn_redlist_categories -> true
        true -> false
      end
    )
  end
end
