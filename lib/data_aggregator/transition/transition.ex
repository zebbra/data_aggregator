defmodule DataAggregator.Transition do
  use Ash.Api, extensions: [AshAdmin.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Transition.Registry
  end

  admin do
    show? true
  end

end
