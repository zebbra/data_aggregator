defmodule DataAggregator.CatalogOfLife.RestAPI do
  @moduledoc """
  Functions to interact with the Catalog of Life (CoL) RestAPI's in order to encode taxonomy data
  """

  alias DataAggregator.Cache.HttpDiskCache

  @minute 60
  @hour 60 * @minute
  @day 24 * @hour
  @month 30 * @day

  @spec parse_name(String.t()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  def parse_name(unparsed_scientific_name)

  def parse_name(nil), do: {:error, "Can't parse scientific name. It must not be nil."}
  def parse_name(""), do: {:error, "Can't parse scientific name. It must not be empty."}

  def parse_name(unparsed_scientific_name) do
    [params: [q: unparsed_scientific_name]]
    |> Req.new()
    |> HttpDiskCache.attach()
    |> Req.get(
      url: "https://api.checklistbank.org/parser/name",
      max_cache_age_seconds: @month
    )
  end

  @spec lookup_species_by_name(String.t()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  def lookup_species_by_name(unparsed_scientific_name)

  def lookup_species_by_name(nil), do: {:error, "Can't lookup species by name. It must not be nil."}

  def lookup_species_by_name(""), do: {:error, "Can't lookup species by name. It must not be empty."}

  def lookup_species_by_name(scientific_name) do
    case [
           params: [
             q: scientific_name,
             content: "SCIENTIFIC_NAME",
             fuzzy: true,
             maxRank: "KINGDOM",
             offset: 0,
             limit: 1
           ]
         ]
         |> Req.new()
         |> HttpDiskCache.attach()
         |> Req.get(
           url: "https://api.checklistbank.org/dataset/3LXR/nameusage/search",
           max_cache_age_seconds: @month
         ) do
      {:ok, %Req.Response{} = response} -> {:ok, response}
      error -> error
    end
  end
end
