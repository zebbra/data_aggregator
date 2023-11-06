defmodule DataAggregator.Platform.Registry do
  @moduledoc """
  Registry for `DataAggregator.Platform` Ash API.
  """

  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Platform.Institution
    entry DataAggregator.Platform.Collection
    entry DataAggregator.Platform.ImportFile
  end
end
