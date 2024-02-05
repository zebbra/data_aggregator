class_diagram = Path.expand("jobs-mermaid-class-diagram.md", __DIR__)

defmodule DataAggregator.Jobs do
  @moduledoc """
  Jobs API

  ## Resources

  #{File.read!(class_diagram)}
  """

  use Ash.Api

  # ensure module is recompiled when the class diagram changes
  @external_resource class_diagram

  resources do
    registry DataAggregator.Jobs.Registry
  end
end
