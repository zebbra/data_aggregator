defmodule DataAggregatorApi.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for DataAggregator using `AshGraphql`.
  """

  use Absinthe.Schema

  use AshGraphql,
    apis: [
      DataAggregator.Platform,
      DataAggregator.Taxonomy,
      DataAggregator.Records
    ]

  # The query and mutation blocks is where you can add custom absinthe code
  query do
  end

  mutation do
  end
end
