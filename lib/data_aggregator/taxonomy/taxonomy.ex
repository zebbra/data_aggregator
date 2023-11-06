defmodule DataAggregator.Taxonomy do
  @moduledoc """
  Taxonomy API

  ## Resources

  #{"taxonomy-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Taxonomy.Registry
  end

  graphql do
    authorize? false
  end
end
