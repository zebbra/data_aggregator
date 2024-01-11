defmodule DataAggregator.Platform do
  # ensure module is recompiled when the class diagram changes
  @class_diagram Path.expand("platform-mermaid-class-diagram.md", __DIR__)
  @external_resource @class_diagram

  @moduledoc """
  Platform API

  ## Resources

  #{File.read!(@class_diagram)}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  resources do
    registry DataAggregator.Platform.Registry
  end

  graphql do
    authorize? false
  end

  json_api do
    prefix "/api/json"
  end
end
