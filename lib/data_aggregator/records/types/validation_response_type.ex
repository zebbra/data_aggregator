validation_response_types = [
  validated: "Validated",
  not_validated: "Not validated"
]

defmodule DataAggregator.Records.ValidationResponseType do
  @moduledoc """
  Enum to define the type of a `DataAggregator.Records.ValidationResponse`.
  """

  use Ash.Type.Enum, values: Enum.map(validation_response_types, fn {key, _value} -> key end)

  @validation_response_types validation_response_types
  @doc """
    Returns all possible validation response types.
  """
  def get_validation_types, do: @validation_response_types

  @doc """
    Returns all possible validation response type options.
  """
  def get_validation_response_type_options, do: Enum.map(@validation_response_types, fn {key, value} -> {value, key} end)
end
