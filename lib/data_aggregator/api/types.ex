defmodule DataAggregator.Types.Api do
  @moduledoc """
  Module for defining types used in the Gbif and OpenCageData API client modules
  """

  @type response :: {:ok, Req.Response.t()} | {:error, Exception.t()}

  @type response_body :: {:ok, binary() | term()} | {:error, String.t()}

  @type params :: keyword() | map()
end
