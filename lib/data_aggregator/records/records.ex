defmodule DataAggregator.Records do
  @moduledoc """
  Data API

  ## Resources

  #{"records-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Records.Registry
  end

  graphql do
    authorize? false
  end

  json_api do
    prefix "/api/json"
  end
end
