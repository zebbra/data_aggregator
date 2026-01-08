catalogs = [
  :gbif_taxonomy,
  :geo_reverse,
  :geo_forward,
  :swiss_species,
  :gbif_iucn_redlist,
  :relate_images,
  :convert_dates
]

defmodule DataAggregator.Taxonomy.Catalog do
  @moduledoc """
  Enum to define all catalogs which we use to encode records
  """
  use Ash.Type.Enum, values: catalogs

  @catalogs catalogs

  def get_catalogs, do: @catalogs

  def get_translated_catalogs do
    Enum.map(get_catalogs(), &translate_catalog/1)
  end

  def translate_catalog(catalog) do
    case catalog do
      :gbif_taxonomy -> "GBIF Taxonomy"
      :geo_reverse -> "Geo Reverse"
      :geo_forward -> "Geo Forward"
      :swiss_species -> "Swiss Species"
      :gbif_iucn_redlist -> "GBIF IUCN Redlist"
      :relate_images -> "Relate Images"
      :convert_dates -> "Date Conversion"
      _ -> "Unknown Catalog"
    end
  end

  def get_input_attributes(catalog) do
    case catalog do
      :gbif_taxonomy ->
        [
          {:tax_scientific_name, :name},
          {:tax_kingdom, :kingdom},
          {:tax_phylum, :phylum},
          {:tax_class, :class},
          {:tax_order, :order},
          {:tax_family, :family}
        ]

      :geo_reverse ->
        []

      :geo_forward ->
        []

      :swiss_species ->
        [{:tax_scientific_name, :tax_scientific_name}]

      :gbif_iucn_redlist ->
        [{:tax_taxon_id, nil}]

      :relate_images ->
        []

      :convert_dates ->
        [
          {:eve_event_date, :eve_event_date},
          {:eve_day, :eve_day},
          {:eve_month, :eve_month},
          {:eve_year, :eve_year},
          {:eve_end_of_period_day, :eve_end_of_period_day},
          {:eve_end_of_period_month, :eve_end_of_period_month},
          {:eve_end_of_period_year, :eve_end_of_period_year}
        ]

      _ ->
        throw("no input attributes defined for catalog: #{catalog}")
    end
  end

  def get_input_dwc_attributes(catalog) do
    catalog |> get_input_attributes() |> Enum.map(fn {key, _value} -> key end)
  end

  def get_output_attributes(catalog) do
    case catalog do
      :gbif_taxonomy ->
        [
          {:tax_kingdom, :kingdom},
          {:tax_phylum, :phylum},
          {:tax_class, :class},
          {:tax_family, :family},
          {:tax_order, :order},
          {:tax_genus, :genus},
          {:tax_scientific_name, :scientificName},
          {:tax_taxon_id, :key},
          {:tax_taxon_id, :acceptedUsageKey}
        ]

      :geo_reverse ->
        [
          {:loc_municipality, "city"},
          {:loc_continent, "continent"},
          {:loc_country, "country"},
          {:loc_country_code, "country_code"},
          {:loc_state_province, "state"},
          {:loc_swiss_coordinates_lv03_x, "loc_swiss_coordinates_lv03_x"},
          {:loc_swiss_coordinates_lv03_y, "loc_swiss_coordinates_lv03_y"},
          {:loc_swiss_coordinates_lv95_x, "loc_swiss_coordinates_lv95_x"},
          {:loc_swiss_coordinates_lv95_y, "loc_swiss_coordinates_lv95_y"},
          {:loc_decimal_longitude, "loc_decimal_longitude"},
          {:loc_decimal_latitude, "loc_decimal_latitude"}
        ]

      :geo_forward ->
        [
          {:loc_continent, "continent"},
          {:loc_country, "country"},
          {:loc_country_code, "country_code"},
          {:loc_state_province, "state"}
        ]

      :swiss_species ->
        [
          {:tax_taxon_id_ch, :taxon_id_ch},
          {:tax_accepted_name_usage, :accepted_name_usage},
          {:tax_taxon_rank, :rank},
          {:oth_swiss_species_center, :center},
          {:oth_swiss_species_registered_at, :registered_at},
          {:oth_swiss_species_registered, :registered}
        ]

      :gbif_iucn_redlist ->
        [
          {:iucn_redlist_category, "code"}
        ]

      :relate_images ->
        [{:mte_associated_media, :mte_associated_media}]

      :convert_dates ->
        [
          {:eve_event_date, :eve_event_date},
          {:eve_day, :eve_day},
          {:eve_month, :eve_month},
          {:eve_year, :eve_year},
          {:eve_end_of_period_day, :eve_end_of_period_day},
          {:eve_end_of_period_month, :eve_end_of_period_month},
          {:eve_end_of_period_year, :eve_end_of_period_year}
        ]

      _ ->
        throw("no output attributes defined for catalog: #{catalog}")
    end
  end

  def get_output_dwc_attributes(catalog) do
    catalog |> get_output_attributes() |> Enum.map(fn {key, _value} -> key end)
  end

  def get_all_output_dwc_attributes do
    get_catalogs()
    |> Enum.flat_map(&get_output_dwc_attributes/1)
    |> Enum.uniq()
  end
end
