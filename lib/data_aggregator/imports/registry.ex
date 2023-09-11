defmodule DataAggregator.Imports.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Imports.Provider
    entry DataAggregator.Imports.Import
    entry DataAggregator.Imports.Collection
  end
end
