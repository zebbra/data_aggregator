defmodule DataAggregator.Platform.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Platform.Institution
    entry DataAggregator.Platform.Collection
  end
end
