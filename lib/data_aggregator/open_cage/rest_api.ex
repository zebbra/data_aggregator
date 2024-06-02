defmodule DataAggregator.Opencage.RestAPI do
  @moduledoc """
    Client for the OpenCageData API
  """
  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Types.Api

  @geo_api_url "https://api.opencagedata.com/geocode/v1/json"
  @hour 60 * 60
  @day 24 * @hour
  @month 30 * @day

  @spec fetch(Api.params()) :: Api.response()
  def fetch(request_params) do
    req =
      HttpDiskCache.attach(Req.new(params: request_params))

    Req.get(req, url: @geo_api_url, max_cache_age_seconds: @month)
  end
end
