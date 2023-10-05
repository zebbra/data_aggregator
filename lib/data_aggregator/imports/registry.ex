defmodule DataAggregator.Imports.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Imports.Institution
    entry DataAggregator.Imports.ImportFile
    entry DataAggregator.Imports.Collection
    entry DataAggregator.Imports.Import
    entry DataAggregator.Imports.StaticAsset
  end
end
