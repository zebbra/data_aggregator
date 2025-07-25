defmodule DataAggregator.Records.DataLayerType do
  @moduledoc """
  Enum to define types of Datalayer which can be choosen for data exporting.
  """
  use Ash.Type.Enum, values: [:raw, :encoded, :validated]
end
