collection_types = [
  zoology: "Zoology",
  botany: "Botany",
  geology: "Geology",
  paleontology: "Paleontology"
]

defmodule DataAggregator.Records.CollectionType do
  @moduledoc """
  Enum to define the type of a `DataAggregator.Records.Collection`.
  """

  use Ash.Type.Enum, values: Enum.map(collection_types, fn {key, _value} -> key end)

  @collection_types collection_types

  @doc """
    Returns all possible collection types.
  """
  def get_collection_types, do: @collection_types

  @doc """
    Returns all possible collection type options.
  """
  def get_collection_type_options, do: Enum.map(@collection_types, fn {key, value} -> {value, key} end)
end
