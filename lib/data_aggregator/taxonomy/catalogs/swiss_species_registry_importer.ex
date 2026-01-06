defmodule DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistryImporter do
  @moduledoc """
  Import Swiss Species Registry catalog from JSON file.

  The JSON structure is:
  ```json
  {
    "Scientific Name": {
      "result": [{
        "id": "center:id",
        "usage": {
          "status": "accepted" | "synonym",
          "label": "...",
          "name": { "rank": "..." },
          "accepted": { "name": { "label": "..." } }  # only for synonyms
        }
      }]
    }
  }
  ```

  ## Center Mapping

  The center is extracted from the `id` field (e.g., "infofauna:10000" -> "infofauna").
  The "nism" center is mapped to `:swissbryophytes`.
  """

  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry

  require Logger

  @center_mapping %{
    "infofauna" => :infofauna,
    "infoflora" => :infoflora,
    "nism" => :swissbryophytes,
    "swissfungi" => :swissfungi,
    "swisslichens" => :swisslichens,
    "vogelwarte" => :vogelwarte
  }

  @doc """
  Import Swiss Species Registry from a JSON file.
  """
  @spec import_from_json(String.t()) :: :ok
  def import_from_json(path) do
    Logger.info("[swiss_species_registry_importer] Starting import from #{path}")

    path
    |> Path.expand()
    |> File.read!()
    |> Jason.decode!()
    |> Enum.each(&import_entry/1)

    Logger.info("[swiss_species_registry_importer] Import completed")
    :ok
  end

  defp import_entry({name, %{"result" => []}}) do
    Logger.warning("[swiss_species_registry_importer] No results found for #{name} in Swiss Species Registry.")
  end

  defp import_entry({name, %{"result" => results}}) when length(results) > 1 do
    Logger.error("[swiss_species_registry_importer] Duplicate entries found for #{name} in Swiss Species Registry.")
  end

  defp import_entry({name, %{"result" => [result]}}) do
    parsed_attrs = parse_attrs(result)

    Logger.info("importing swiss species registry entry: #{inspect(parsed_attrs)}")
    SwissSpeciesRegistry.create!(parsed_attrs)
  rescue
    error ->
      Logger.error("could not import swiss species registry entry: #{inspect(name)}, reason was: #{inspect(error)}")

      throw(error)
  end

  defp parse_attrs(%{"id" => id, "usage" => usage}) do
    {center, taxon_id_ch} = parse_id(id)
    scientific_name = usage["label"]
    status = usage["status"]
    rank = get_in(usage, ["name", "rank"])
    accepted_name_usage = get_accepted_name_usage(usage, status)

    %{
      scientific_name: scientific_name,
      taxon_id_ch: taxon_id_ch,
      accepted_name_usage: accepted_name_usage,
      center: center,
      rank: rank,
      status: status
    }
  end

  @doc """
  Parse the ID field to extract center and taxon ID.

  ## Examples

      iex> parse_id("infofauna:10000")
      {:infofauna, "10000"}

      iex> parse_id("infoflora:12345")
      {:infoflora, "12345"}

      iex> parse_id("nism:67890")
      {:swissbryophytes, "67890"}

      iex> parse_id("swissfungi:11111")
      {:swissfungi, "11111"}

      iex> parse_id("swisslichens:22222")
      {:swisslichens, "22222"}

      iex> parse_id("vogelwarte:33333")
      {:vogelwarte, "33333"}

      iex> parse_id("INFOFAUNA:10000")
      {:infofauna, "10000"}

  """
  @spec parse_id(String.t()) :: {atom(), String.t()}
  def parse_id(id) do
    [center_str, taxon_id] = String.split(id, ":")
    center = Map.fetch!(@center_mapping, String.downcase(center_str))
    {center, taxon_id}
  end

  @doc """
  Get the accepted name usage based on the status.

  For accepted taxa, returns usage.label.
  For synonyms, returns usage.accepted.name.label.
  For unknown statuses, returns nil.

  ## Examples

      iex> get_accepted_name_usage(%{"label" => "Species name"}, "accepted")
      "Species name"

      iex> get_accepted_name_usage(%{"label" => "Synonym name", "accepted" => %{"name" => %{"label" => "Accepted species name"}}}, "synonym")
      "Accepted species name"

      iex> get_accepted_name_usage(%{"label" => "Some name"}, "unknown")
      nil

  """
  @spec get_accepted_name_usage(map(), String.t()) :: String.t() | nil
  def get_accepted_name_usage(usage, "accepted"), do: usage["label"]
  def get_accepted_name_usage(usage, "synonym"), do: get_in(usage, ["accepted", "name", "label"])
  def get_accepted_name_usage(_usage, _status), do: nil
end
