defmodule DataAggregator.IUCN.RestAPI do
  @moduledoc """
  Module to interact with the IUCN Rest API
  """

  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Types.Api

  require Logger

  @minute 60
  @hour 60 * @minute
  @day 24 * @hour
  @month 30 * @day

  @doc """
  Get the IUCN Redlist category from the IUCN Rest API for a given genus and species (specific epithet)
  """
  @spec get_iucn_redlist_category(String.t(), String.t()) :: Api.response()
  def get_iucn_redlist_category(genus, specific_epithet) do
    [
      params: [genus_name: genus, species_name: specific_epithet],
      headers: %{authorization: System.get_env("IUCN_API_TOKEN")}
    ]
    |> Req.new()
    |> HttpDiskCache.attach()
    |> Req.get(
      url: "https://api.iucnredlist.org/api/v4/taxa/scientific_name",
      max_cache_age_seconds: @month
    )
  end
end
