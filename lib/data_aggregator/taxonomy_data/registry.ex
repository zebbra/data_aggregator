defmodule DataAggregator.TaxonomyData.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.TaxonomyData.Record
  end
end
