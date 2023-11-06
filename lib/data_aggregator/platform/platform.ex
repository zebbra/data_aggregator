defmodule DataAggregator.Platform do
  @moduledoc """
  Platform API

  ## Resources

  #{"platform-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Platform.Registry
  end

  graphql do
    authorize? false
  end
end
