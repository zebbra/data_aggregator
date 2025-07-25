collection_types = [
  zoology: "Zoology",
  botany: "Botany",
  paleontology: "Paleontology"
]

defmodule DataAggregator.Records.CollectionType do
  @moduledoc """
  Enum to define the type of a `DataAggregator.Records.Collection`.
  """

  use Ash.Type.Enum, values: Enum.map(collection_types, fn {key, _value} -> key end)

  @collection_types collection_types

  @doc """
    Returns all possible collection types.
  """
  def get_collection_types, do: @collection_types

  @doc """
    Returns all possible collection type options.
  """
  def get_collection_type_options, do: Enum.map(@collection_types, fn {key, value} -> {value, key} end)

  @doc """
  Determines if an attribute is visible for a given collection type.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def visible?(collection_type, attribute) when is_atom(collection_type) and is_atom(attribute) do
    case collection_type do
      :botany ->
        case attribute do
          :picture -> true
          :iucn_redlist -> true
          :idf_type_status -> true
          :tax_scientific_name -> true
          :idf_verbatim_identification -> true
          :occ_occurrence_id -> true
          :mte_catalog_number -> true
          :mte_recorded_by -> true
          :idf_identified_by -> true
          :eve_event_date -> true
          :loc_state_province -> true
          :loc_verbatim_elevation -> true
          :loc_decimal_latitude -> true
          :oth_swiss_species_center -> true
          :state -> true
          :publication_status -> true
          :validation_status -> true
          :mids_level -> true
          :updated_at -> true
          _ -> false
        end

      :zoology ->
        case attribute do
          :picture -> true
          :iucn_redlist -> true
          :tax_scientific_name -> true
          :idf_verbatim_identification -> true
          :occ_occurrence_id -> true
          :mte_catalog_number -> true
          :eve_field_number -> true
          :idf_identified_by -> true
          :eve_event_date -> true
          :loc_state_province -> true
          :loc_verbatim_elevation -> true
          :loc_decimal_latitude -> true
          :oth_swiss_species_center -> true
          :state -> true
          :publication_status -> true
          :validation_status -> true
          :mids_level -> true
          :updated_at -> true
          _ -> false
        end

      :paleontology ->
        case attribute do
          :picture -> true
          :iucn_redlist -> true
          :idf_type_status -> true
          :tax_scientific_name -> true
          :idf_verbatim_identification -> true
          :occ_occurrence_id -> true
          :mte_catalog_number -> true
          :mte_recorded_by -> true
          :idf_identified_by -> true
          :eve_event_date -> true
          :loc_state_province -> true
          :loc_verbatim_elevation -> true
          :loc_decimal_latitude -> true
          :oth_swiss_species_center -> true
          :state -> true
          :publication_status -> true
          :validation_status -> true
          :mids_level -> true
          :updated_at -> true
          _ -> false
        end

      _ ->
        false
    end
  end
end
