defmodule DataAggregator.Records.Record.Calculations.Mids.LevelThree do
  @moduledoc """
    Calculation for MIDS level three to indicate if a record fulfills the requirements for MIDS level three.
  """
  use Ash.Resource.Calculation

  import Ash.Expr

  alias __MODULE__

  @impl true
  def load(_query, _opts, _context) do
    [:mids_level_one, :mids_level_two]
  end

  @impl true
  def expression(_opts, _context) do
    expr(mids_level_two and ^LevelThree.requirements_met())
  end

  def requirements_met do
    expr(
      ^has_a_collection() and
        ^has_textual_location() and
        ^has_coordinates() and
        ^has_all_other_important_fields()
    )
  end

  defp has_textual_location do
    expr(
      ^has_non_nil_loc_continent() and
        ^has_non_nil_loc_country() and
        ^has_non_nil_loc_county() and
        ^has_non_nil_loc_higher_geography() and
        ^has_non_nil_loc_locality() and
        ^has_non_nil_loc_state_province() and
        ^has_non_nil_loc_verbatim_depth() and
        ^has_non_nil_loc_verbatim_elevation()
    )
  end

  defp has_coordinates do
    expr(
      ^has_non_nil_loc_decimal_latitude() and
        ^has_non_nil_loc_decimal_longitude()
    )
  end

  defp has_all_other_important_fields do
    expr(
      ^has_non_nil_eve_event_date() and
        ^has_non_nil_mte_recorded_by() and
        ^has_non_nil_idf_type_status() and
        ^has_non_nil_tax_original_name_usage() and
        ^has_non_nil_mte_year_collection_entrance() and
        ^has_non_nil_occ_occurrence_id()
    )
  end

  defp has_a_collection do
    expr(not is_nil(collection.code))
  end

  defp has_non_nil_eve_event_date do
    expr(not is_nil(encoded_record.eve_event_date))
  end

  defp has_non_nil_mte_recorded_by do
    expr(not is_nil(encoded_record.mte_recorded_by))
  end

  defp has_non_nil_idf_type_status do
    expr(not is_nil(encoded_record.idf_type_status))
  end

  defp has_non_nil_tax_original_name_usage do
    expr(not is_nil(encoded_record.tax_original_name_usage))
  end

  defp has_non_nil_loc_continent do
    expr(not is_nil(encoded_record.loc_continent))
  end

  defp has_non_nil_loc_country do
    expr(not is_nil(encoded_record.loc_country))
  end

  defp has_non_nil_loc_county do
    expr(not is_nil(encoded_record.loc_county))
  end

  defp has_non_nil_loc_decimal_latitude do
    expr(not is_nil(encoded_record.loc_decimal_latitude))
  end

  defp has_non_nil_loc_decimal_longitude do
    expr(not is_nil(encoded_record.loc_decimal_longitude))
  end

  defp has_non_nil_loc_higher_geography do
    expr(not is_nil(encoded_record.loc_higher_geography))
  end

  defp has_non_nil_loc_locality do
    expr(not is_nil(encoded_record.loc_locality))
  end

  defp has_non_nil_loc_state_province do
    expr(not is_nil(encoded_record.loc_state_province))
  end

  defp has_non_nil_loc_verbatim_depth do
    expr(not is_nil(encoded_record.loc_verbatim_depth))
  end

  defp has_non_nil_loc_verbatim_elevation do
    expr(not is_nil(encoded_record.loc_verbatim_elevation))
  end

  defp has_non_nil_mte_year_collection_entrance do
    expr(not is_nil(encoded_record.mte_year_collection_entrance))
  end

  defp has_non_nil_occ_occurrence_id do
    expr(not is_nil(encoded_record.occ_occurrence_id))
  end
end
