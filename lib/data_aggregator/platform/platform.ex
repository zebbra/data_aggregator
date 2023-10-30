defmodule DataAggregator.Platform do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Platform.Registry
  end

  graphql do
    authorize? false
  end
end
