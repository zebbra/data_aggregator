defmodule DataAggregator.Taxonomy do
  # ensure module is recompiled when the class diagram changes
  @class_diagram Path.expand("taxonomy-mermaid-class-diagram.md", __DIR__)
  @external_resource @class_diagram

  @moduledoc """
  Taxonomy API

  ## Resources

  #{File.read!(@class_diagram)}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Taxonomy.Registry
  end

  graphql do
    authorize? false
  end
end
