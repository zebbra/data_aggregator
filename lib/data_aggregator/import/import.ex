defmodule DataAggregator.Import do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api]

  resources do
    registry DataAggregator.Import.Registry
  end

  admin do
    show? true
  end

  graphql do
    authorize? false
  end
end
