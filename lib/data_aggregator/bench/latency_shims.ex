defmodule DataAggregator.Bench.LatencyShims do
  @moduledoc false
end

defmodule DataAggregator.Bench.LatencyShims.Gbif do
  @moduledoc false
  use DataAggregator.Bench.LatencyShim, target: DataAggregator.Gbif.RestAPIStub
end

defmodule DataAggregator.Bench.LatencyShims.Opencage do
  @moduledoc false
  use DataAggregator.Bench.LatencyShim, target: DataAggregator.Opencage.RestAPIStub
end

defmodule DataAggregator.Bench.LatencyShims.CatalogOfLife do
  @moduledoc false
  use DataAggregator.Bench.LatencyShim, target: DataAggregator.CatalogOfLife.RestAPIStub
end
