defmodule DataAggregator.TaxonomyCatalog do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.TaxonomyCatalog.Registry
  end

  graphql do
    authorize? false
  end
end
