defmodule DataAggregator.TaxonomyData do
  use Ash.Api, extensions: [AshAdmin.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.TaxonomyData.Registry
  end

  admin do
    show? true
  end
end
