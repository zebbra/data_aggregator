defmodule DataAggregator.TaxonomyCatalog.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.TaxonomyCatalog.Catalog
    entry DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy
    entry DataAggregator.TaxonomyCatalog.EntityEdge
    entry DataAggregator.TaxonomyCatalog.Entity
    entry DataAggregator.TaxonomyCatalog.DwcAttribute
  end
end
