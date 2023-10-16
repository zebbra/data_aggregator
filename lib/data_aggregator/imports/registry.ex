defmodule DataAggregator.Imports.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Imports.ImportChangeEvent
    entry DataAggregator.Imports.ImportRecord2Run
    entry DataAggregator.Imports.Institution
    entry DataAggregator.Imports.ImportRecord
    entry DataAggregator.Imports.StaticAsset
    entry DataAggregator.Imports.ImportFile
    entry DataAggregator.Imports.ImportRecord2ImportFile
  end
end
