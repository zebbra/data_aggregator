defmodule DataAggregator.TaxonomyCatalog do
  use Ash.Api, extensions: [AshAdmin.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.TaxonomyCatalog.Registry
  end

  admin do
    show? true
  end
end
