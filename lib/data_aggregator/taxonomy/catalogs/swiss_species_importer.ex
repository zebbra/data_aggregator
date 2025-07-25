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

  def parse_attribute({"TAXONIDCH", value}), do: {"taxon_id_ch", parse_taxon_id_ch(value)}

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

  @doc """
      parses the "center" column of the csv file

      #Examples:

        iex> parse_attribute({"center", "infofauna"})
        {"center", :infofauna}

        iex> parse_attribute({"center", "InfoFauna"})
        {"center", :infofauna}

        iex> parse_attribute({"center", "vogelwarte"})
        {"center", :vogelwarte}

        iex> parse_attribute({"center", "swissbryophytes"})
        {"center", :swissbryophytes}

        iex> parse_attribute({"center", "swisslichens"})
        {"center", :swisslichens}

        iex> parse_attribute({"center", "swissfungi"})
        {"center", :swissfungi}

        iex> parse_attribute({"center", nil})
        ** (RuntimeError) center is nil, but should be a string, please prvide a valid infospecies center for each taxon

        iex> parse_attribute({"center", "NOT-EXISTING-CENTER"})
        ** (RuntimeError) center not found: "NOT-EXISTING-CENTER". eighter provide a valid center or add it to the list of valid centers by adding it to the InfospeciesCenters module
  """
  def parse_attribute({"center", value}) do
    case find_center_by_name(value) do
      nil ->
        raise(
          "center not found: #{inspect(value)}. eighter provide a valid center or add it to the list of valid centers by adding it to the InfospeciesCenters module"
        )

      name ->
        {"center", name}
    end
  end

  def parse_attribute({attribute, _value}), do: raise("unknown attribute: #{inspect(attribute)}")

  @doc """
    parses the swiss taxon id (i.e.: infofauna:70710) from the csv file

    #Examples:

      iex> parse_taxon_id_ch("infofauna:70710")
      "70710"

      iex> parse_taxon_id_ch("InfoFauna:70710")
      "70710"

      iex> parse_taxon_id_ch("infoflora:70710")
      "70710"

      iex> parse_taxon_id_ch("vogelwarte:70710")
      "70710"

      iex> parse_taxon_id_ch("swissbryophytes:70710")
      "70710"

      iex> parse_taxon_id_ch("swisslichens:70710")
      "70710"

      iex> parse_taxon_id_ch("swissfungi:70710")
      "70710"

      iex> parse_taxon_id_ch("NOT-EXISTING-CENTER:70710")
      "70710"

  """
  def parse_taxon_id_ch(name_and_value) do
    maybe_split_value(name_and_value)
  end

  defp maybe_split_value(name_and_value) do
    if String.contains?(name_and_value, ":") do
      [_name, value] = String.split(name_and_value, ":")

      value
    end
  end

  defp find_center_by_name(name) do
    Enum.find(InfospeciesCenters.get_center_names(), fn center_name ->
      to_string(center_name) == String.downcase(name)
    end)
  end
end
