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
    entry DataAggregator.Transition.RecordChangeEvent
    entry DataAggregator.Transition.Annotation
    entry DataAggregator.TaxonomyData.Record
    entry DataAggregator.Imports.Import
    entry DataAggregator.Imports.Collection
    entry DataAggregator.Imports.StaticAsset
    entry DataAggregator.Imports.ImportFile
    entry DataAggregator.Imports.Institution
  end
end
