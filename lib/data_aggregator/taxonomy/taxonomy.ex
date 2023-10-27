defmodule DataAggregator.Taxonomy do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Taxonomy.Registry
  end

  graphql do
    authorize? false
  end
end
