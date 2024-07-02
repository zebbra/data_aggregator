defmodule DataAggregatorApi.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for DataAggregator using `AshGraphql`.
  """

  # TODO: Fixme! if we use the Absinthe.Schema module, we get an error
  # that the root query must not be empty.
  # use Absinthe.Schema

  # TODO: uncomment me once issue noted above is fixed
  # use AshGraphql,
  #   domains: [
  #     DataAggregator.Platform,
  #     DataAggregator.Taxonomy,
  #     DataAggregator.Records
  #   ]

  # The query and mutation blocks is where you can add custom absinthe code
  # TODO: uncomment me once issue noted above is fixed
  # query do
  #   # Fields go here
  # end

  # TODO: uncomment me once issue noted above is fixed
  # mutation do
  #   # Fields go here
  # end
end
