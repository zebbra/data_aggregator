defmodule DataAggregator.Data do
  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  @moduledoc """
  ## Resources

  #{"data-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  resources do
    registry DataAggregator.Data.Registry
  end

  graphql do
    authorize? false
  end
end
