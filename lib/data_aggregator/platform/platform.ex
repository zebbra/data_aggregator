class_diagram = Path.expand("platform-mermaid-class-diagram.md", __DIR__)

defmodule DataAggregator.Platform do
  @moduledoc """
  Platform API

  ## Resources

  #{File.read!(class_diagram)}
  """

  use Ash.Domain, extensions: [AshJsonApi.Domain]

  # ensure module is recompiled when the class diagram changes
  @external_resource class_diagram

  resources do
    resource DataAggregator.Platform.Institution
  end

  json_api do
    prefix "/api/json"
  end
end
