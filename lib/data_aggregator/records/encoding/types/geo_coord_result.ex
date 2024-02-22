defmodule DataAggregator.Records.Encoding.GeoCoordResult do
  @moduledoc """
    This module is represents the result of a coordinate conversion
  """
  alias DataAggregator.Misc.Coordinates

  @type t :: {:ok, Coordinates.t()} | {:error, any()}
end
