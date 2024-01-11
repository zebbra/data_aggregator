defmodule DataAggregator.Taxonomy.Catalogs.SwissSpeciesImporter do
  @moduledoc """
  Import swiss species catalog from csv file
  """

  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  def import_swiss_species_catalog_from_csv(path) do
    path
    |> Path.expand()
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.each(&import_swiss_species_from_csv/1)
  end

  defp import_swiss_species_from_csv(attrs) do
    parsed_attrs = parse_csv_attributes(attrs)

    SwissSpecies.create!(parsed_attrs)
  end

  defp parse_csv_attributes(attrs) do
    attrs
    |> Enum.map(&parse_attribute/1)
    |> Map.new()
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

  def parse_attribute({attribute, _value}), do: raise("unknown attribute: #{inspect(attribute)}")
end
