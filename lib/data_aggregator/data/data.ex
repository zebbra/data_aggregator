defmodule DataAggregator.Data do
  @moduledoc """
  Data API

  ## Resources

  #{"data-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Data.Registry
  end

  graphql do
    authorize? false
  end
end
