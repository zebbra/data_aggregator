defmodule DataAggregator.Taxonomy.Registry do
  @moduledoc """
  Ash registry for `DataAggregator.Taxonomy` context.
  """

  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Taxonomy.DwcAttribute
    entry DataAggregator.Taxonomy.Catalog
    entry DataAggregator.Taxonomy.AttributeResolvingStrategy
  end
end
