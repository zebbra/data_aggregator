defmodule DataAggregator.Records.Record.Calculations.IucnRedlistCategoryGroup do
  @moduledoc """
  This module provides a calculation for the IUCN Red List category group.
  """

  use Ash.Resource.Calculation

  require Ash.Query

  @threatened_categories ["VU", "CR", "EN"]
  @less_threatened_categories ["LC", "NT"]
  @extinct_categories ["RE", "EW", "EX"]
  @uncertain_data_categories ["NE", "DD"]

  @impl true
  def calculate(records, _opts, _ctx) do
    Enum.map(records, &map_iucn_category_to_group(&1))
  end

  defp map_iucn_category_to_group(%{encoded_record: %{iucn_redlist_category: iucn_redlist_category}}) do
    cond do
      iucn_redlist_category in @threatened_categories ->
        "threatened"

      iucn_redlist_category in @less_threatened_categories ->
        "less_threatened"

      iucn_redlist_category in @extinct_categories ->
        "extinct"

      iucn_redlist_category in @uncertain_data_categories ->
        "uncertain_data"

      is_nil(iucn_redlist_category) ->
        "uncertain_data"

      true ->
        nil
    end
  end

  defp map_iucn_category_to_group(%{encoded_record: nil}) do
    nil
  end

  defp map_iucn_category_to_group(_record) do
    nil
  end

  @impl true
  def expression(_opts, _context) do
    expr(
      cond do
        encoded_record.iucn_redlist_category in @threatened_categories ->
          "threatened"

        encoded_record.iucn_redlist_category in @less_threatened_categories ->
          "less_threatened"

        encoded_record.iucn_redlist_category in @extinct_categories ->
          "extinct"

        encoded_record.iucn_redlist_category in @uncertain_data_categories ->
          "uncertain_data"

        is_nil(encoded_record.iucn_redlist_category) ->
          "uncertain_data"

        true ->
          nil
      end
    )
  end
end
