defmodule DataAggregator.TaxonomyData.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.TaxonomyData.Record
    entry DataAggregator.Imports.Import
    entry DataAggregator.Transition.Annotation
    entry DataAggregator.Transition.RecordChangeEvent
    entry DataAggregator.Imports.Collection
    entry DataAggregator.Imports.StaticAsset
    entry DataAggregator.Imports.ImportFile
    entry DataAggregator.TaxonomyCatalog.DwcAttribute
    entry DataAggregator.TaxonomyCatalog.Catalog
    entry DataAggregator.Imports.Institution
    entry DataAggregator.Imports.Institution
    entry DataAggregator.TaxonomyCatalog.Entity
    entry DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy
    entry DataAggregator.TaxonomyCatalog.EntityEdge
  end
end
