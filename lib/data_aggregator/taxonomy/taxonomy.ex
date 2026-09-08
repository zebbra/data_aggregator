class_diagram = Path.expand("taxonomy-mermaid-class-diagram.md", __DIR__)

defmodule DataAggregator.Taxonomy do
  @moduledoc """
  Taxonomy API

  ## Resources

  #{File.read!(class_diagram)}
  """

  use Ash.Domain, extensions: [AshJsonApi.Domain]

  # ensure module is recompiled when the class diagram changes
  @external_resource class_diagram

  resources do
    resource DataAggregator.Taxonomy.Catalogs.SwissSpecies
    resource DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry
  end

  json_api do
    prefix "/api/json"
  end
end
