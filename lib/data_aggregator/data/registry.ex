defmodule DataAggregator.Data.Registry do
  @moduledoc """
  Registry for `DataAggregator.Data` Ash API.
  """

  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Data.Record
    entry DataAggregator.Data.RecordImage
  end
end
