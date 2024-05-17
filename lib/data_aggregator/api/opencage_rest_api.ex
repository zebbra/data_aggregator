defmodule DataAggregator.Opencage.RestAPI do
  @moduledoc """
    Client for the OpenCageData API
  """
  alias DataAggregator.Cache.HttpDiskCache

  @geo_api_url "https://api.opencagedata.com/geocode/v1/json"

  @spec fetch(list()) :: {:ok, Req.Response.t()} | {:error, any()}
  def fetch(request_params) do
    req =
      HttpDiskCache.attach(Req.new(params: request_params))

    Req.get(req, url: @geo_api_url, max_cache_age_seconds: 30 * 24 * 60 * 60)
  end
end
