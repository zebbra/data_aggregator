defmodule DataAggregator.Files do
  use Ash.Api

  resources do
    registry DataAggregator.Files.Registry
  end
end
