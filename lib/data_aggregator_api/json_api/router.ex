defmodule DataAggregatorApi.JsonApi.Router do
  @moduledoc false

  use AshJsonApi.Router,
    # The api modules you want to serve
    domains: [
      DataAggregator.Platform,
      DataAggregator.Records,
      DataAggregator.Taxonomy
    ],
    # optionally a json_schema route
    json_schema: "/json_schema",
    # optionally an open_api route
    open_api: "/open_api"
end
