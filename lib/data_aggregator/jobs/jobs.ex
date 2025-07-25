class_diagram = Path.expand("jobs-mermaid-class-diagram.md", __DIR__)

defmodule DataAggregator.Jobs do
  @moduledoc """
  Jobs API

  ## Resources

  #{File.read!(class_diagram)}
  """

  use Ash.Domain

  # ensure module is recompiled when the class diagram changes
  @external_resource class_diagram

  resources do
    resource DataAggregator.Jobs.Job
  end
end
