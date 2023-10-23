defmodule DataAggregator.TaxonomyData do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.TaxonomyData.Registry
  end

  graphql do
    authorize? false
  end
end
