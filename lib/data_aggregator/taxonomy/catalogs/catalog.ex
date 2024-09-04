catalogs = [:gbif_taxonomy, :swiss_species, :geo_reverse, :geo_forward, :gbif_iucn_redlist]

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
      :swiss_species -> "Swiss Species"
      :geo_reverse -> "Geo Reverse"
      :geo_forward -> "Geo Forward"
      :gbif_iucn_redlist -> "GBIF IUCN Redlist"
      _ -> throw("no translation defined for catalog: #{catalog}")
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

      :gbif_iucn_redlist ->
        [{:tax_taxon_id, nil}]

      :swiss_species ->
        [{:tax_taxon_id, :tax_taxon_id}]

      :geo_reverse ->
        []

      :geo_forward ->
        []

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

      :gbif_iucn_redlist ->
        [
          {:iucn_redlist_category, "code"}
        ]

      :swiss_species ->
        [
          {:tax_taxon_id_ch, :taxon_id_ch},
          {:tax_accepted_name_usage, :accepted_name},
          {:tax_accepted_name_usage_id, :accepted_usage_key},
          {:tax_scientific_name, :scientific_name},
          {:tax_taxon_rank, :rank}
        ]

      :geo_reverse ->
        [
          {:loc_municipality, "city"},
          {:loc_continent, "continent"},
          {:loc_country, "country"},
          {:loc_country_code, "country_code"},
          {:loc_state_province, "state"},
          {:loc_swiss_coordinates_x, "loc_swiss_coordinates_x"},
          {:loc_swiss_coordinates_y, "loc_swiss_coordinates_y"},
          {:loc_decimal_longitude, "loc_decimal_longitude"},
          {:loc_decimal_latitude, "loc_decimal_latitude"}
        ]

      :geo_forward ->
        [
          {:loc_municipality, "city"},
          {:loc_continent, "continent"},
          {:loc_country, "country"},
          {:loc_country_code, "country_code"},
          {:loc_state_province, "state"}
        ]

      _ ->
        throw("no output attributes defined for catalog: #{catalog}")
    end
  end

  def get_output_dwc_attributes(catalog) do
    catalog |> get_output_attributes() |> Enum.map(fn {key, _value} -> key end)
  end
end
