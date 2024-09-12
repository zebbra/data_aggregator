defmodule DataAggregator.Records.Record.Calculations.Mids.LevelFour do
  @moduledoc """
    Calculation for MIDS level four to indicate if a record fulfills the requirements for MIDS level four.
  """
  use Ash.Resource.Calculation

  import Ash.Expr

  alias __MODULE__

  @impl true
  def load(_query, _opts, _context) do
    [:mids_level_one, :mids_level_two, :mids_level_three]
  end

  @impl true
  def expression(_opts, _context) do
    expr(mids_level_two and mids_level_three and ^LevelFour.requirements_met())
  end

  def requirements_met do
    expr(
      ^has_non_nil_eve_verbatim_event_date() or
        ^has_identification() or
        ^has_geographic_information() or
        ^has_material_entity_information()
    )
  end

  defp has_identification do
    expr(
      ^has_non_nil_idf_identified_by() or
        ^has_non_nil_idf_identification_qualifier() or
        ^has_non_nil_idf_identification_verification_status() or
        ^has_non_nil_idf_last_verified_by() or
        ^has_non_nil_idf_verbatim_identification()
    )
  end

  defp has_geographic_information do
    expr(
      ^has_non_nil_loc_georeferenced_by() or
        ^has_non_nil_loc_georeference_verification_status() or
        ^has_non_nil_loc_verbatim_coordinates() or
        ^has_non_nil_loc_verbatim_latitude() or
        ^has_non_nil_loc_verbatim_longitude() or
        ^has_non_nil_loc_verbatim_locality()
    )
  end

  defp has_material_entity_information do
    expr(
      ^has_non_nil_mte_associated_media() or
        ^has_non_nil_mte_completeness() or
        ^has_non_nil_mte_other_catalog_numbers() or
        ^has_non_nil_mte_verbatim_label()
    )
  end

  defp has_non_nil_eve_verbatim_event_date do
    expr(not is_nil(encoded_record.eve_verbatim_event_date))
  end

  defp has_non_nil_idf_identified_by do
    expr(not is_nil(encoded_record.idf_identified_by))
  end

  defp has_non_nil_idf_identification_qualifier do
    expr(not is_nil(encoded_record.idf_identification_qualifier))
  end

  defp has_non_nil_idf_identification_verification_status do
    expr(not is_nil(encoded_record.idf_identification_verification_status))
  end

  defp has_non_nil_idf_last_verified_by do
    expr(not is_nil(encoded_record.idf_last_verified_by))
  end

  defp has_non_nil_idf_verbatim_identification do
    expr(not is_nil(encoded_record.idf_verbatim_identification))
  end

  defp has_non_nil_loc_georeferenced_by do
    expr(not is_nil(encoded_record.loc_georeferenced_by))
  end

  defp has_non_nil_loc_georeference_verification_status do
    expr(not is_nil(encoded_record.loc_georeference_verification_status))
  end

  defp has_non_nil_loc_verbatim_coordinates do
    expr(not is_nil(encoded_record.loc_verbatim_coordinates))
  end

  defp has_non_nil_loc_verbatim_latitude do
    expr(not is_nil(encoded_record.loc_verbatim_latitude))
  end

  defp has_non_nil_loc_verbatim_longitude do
    expr(not is_nil(encoded_record.loc_verbatim_longitude))
  end

  defp has_non_nil_loc_verbatim_locality do
    expr(not is_nil(encoded_record.loc_verbatim_locality))
  end

  defp has_non_nil_mte_associated_media do
    expr(not is_nil(encoded_record.mte_associated_media))
  end

  defp has_non_nil_mte_completeness do
    expr(not is_nil(encoded_record.mte_completeness))
  end

  defp has_non_nil_mte_other_catalog_numbers do
    expr(not is_nil(encoded_record.mte_other_catalog_numbers))
  end

  defp has_non_nil_mte_verbatim_label do
    expr(not is_nil(encoded_record.mte_verbatim_label))
  end
end
