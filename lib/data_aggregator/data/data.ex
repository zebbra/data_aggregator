defmodule DataAggregator.Data do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Data.Registry
  end

  graphql do
    authorize? false
  end
end
