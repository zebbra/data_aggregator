defmodule DataAggregator.Records.CollectionType do
  @moduledoc """
  Enum to define the type of a `DataAggregator.Records.Collection`.
  """

  @collection_types [animalia: "Animalia", plantae: "Plantae", other: "Other"]

  use Ash.Type.Enum, values: @collection_types |> Enum.map(fn {key, _value} -> key end)

  @doc """
    Returns all possible collection types.
  """
  def get_collection_types, do: @collection_types

  @doc """
    Returns all possible collection type options.
  """
  def get_collection_type_options,
    do: @collection_types |> Enum.map(fn {key, value} -> {value, key} end)
end
