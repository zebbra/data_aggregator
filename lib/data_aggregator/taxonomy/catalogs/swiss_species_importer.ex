defmodule DataAggregator.Taxonomy.Catalogs.SwissSpeciesImporter do
  @moduledoc """
  Import swiss species catalog from csv file
  """
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  require Logger

  def import_swiss_species_catalog_from_csv(path) do
    path
    |> Path.expand()
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.each(&import_swiss_species_from_csv/1)
  end

  defp import_swiss_species_from_csv(attrs) do
    parsed_attrs = parse_csv_attributes(attrs)

    Logger.info("importing swiss species: #{inspect(parsed_attrs)}")

    SwissSpecies.create!(parsed_attrs)
  rescue
    error ->
      Logger.error("could not import swiss species: #{inspect(attrs)}, reason was: #{inspect(error)}")

      throw(error)
  end

  defp parse_csv_attributes(attrs) do
    Map.new(attrs, &parse_attribute/1)
  end

  # parses the swiss taxon id (i.e.: infofauna:70710) from the csv file
  def parse_attribute({"TAXONIDCH", value}) do
    id = String.replace_leading(value, "infofauna:", "")

    {"taxon_id_ch", id}
  end

  def parse_attribute({"acceptedName", value}) do
    {"accepted_name", value}
  end

  def parse_attribute({"usageKey", value}) do
    {"usage_key", value}
  end

  def parse_attribute({"acceptedUsageKey", value}) do
    {"accepted_usage_key", value}
  end

  def parse_attribute({"scientificName", value}) do
    {"scientific_name", value}
  end

  def parse_attribute({"rank", value}) do
    {"rank", value}
  end

  def parse_attribute({"center", nil}) do
    raise("center is nil, but should be a string, please prvide a valid infospecies center for each taxon")
  end

  def parse_attribute({"center", value}) do
    case Enum.find(InfospeciesCenters.get_center_names(), fn name ->
           to_string(name) == String.downcase(value)
         end) do
      nil ->
        raise(
          "center not found: #{inspect(value)}. eighter provide a valid center or add it to the list of valid centers by adding it to the InfospeciesCenters module"
        )

      name ->
        {"center", name}
    end
  end

  def parse_attribute({attribute, _value}), do: raise("unknown attribute: #{inspect(attribute)}")
end
