defmodule DataAggregator.Records.Record.Calculations.IucnRedlistCategoryGroup do
  @moduledoc """
  This module provides a calculation for the IUCN Red List category group.
  """

  use Ash.Resource.Calculation

  require Ash.Query

  @endangered_categories ["VU", "CR", "EN"]
  @not_threatened_categories ["LC", "NT", "EW", "EX"]
  @other_categories ["NE", "DD"]

  @impl true
  def calculate(records, _opts, _ctx) do
    Enum.map(records, &map_iucn_category_to_group(&1))
  end

  defp map_iucn_category_to_group(%{iucn_redlist_category: iucn_redlist_category}) do
    cond do
      is_nil(iucn_redlist_category) ->
        nil

      iucn_redlist_category in @endangered_categories ->
        "endangered"

      iucn_redlist_category in @not_threatened_categories ->
        "not_threatened"

      iucn_redlist_category in @other_categories ->
        "other"

      true ->
        nil
    end
  end

  @impl true
  def expression(_opts, _context) do
    expr(
      cond do
        is_nil(iucn_redlist_category) ->
          nil

        iucn_redlist_category in @endangered_categories ->
          "endangered"

        iucn_redlist_category in @not_threatened_categories ->
          "not_threatened"

        iucn_redlist_category in @other_categories ->
          "other"

        true ->
          nil
      end
    )
  end
end
