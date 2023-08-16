defmodule DataAggregator.Imports do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api]

  resources do
    registry DataAggregator.Imports.Registry
  end

  admin do
    show? true
  end

  graphql do
    authorize? false
  end
end
