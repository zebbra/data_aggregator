class_diagram = Path.expand("taxonomy-mermaid-class-diagram.md", __DIR__)

defmodule DataAggregator.Taxonomy do
  @moduledoc """
  Taxonomy API

  ## Resources

  #{File.read!(class_diagram)}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  # ensure module is recompiled when the class diagram changes
  @external_resource class_diagram

  resources do
    registry DataAggregator.Taxonomy.Registry
  end

  graphql do
    authorize? false
  end

  json_api do
    prefix "/api/json"
  end
end
