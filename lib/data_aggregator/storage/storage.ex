defmodule DataAggregator.Storage do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Storage.Registry
  end

  graphql do
    authorize? false
  end
end
