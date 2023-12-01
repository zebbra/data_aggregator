defmodule DataAggregator.Jobs do
  # ensure module is recompiled when the class diagram changes
  @class_diagram Path.expand("jobs-mermaid-class-diagram.md", __DIR__)
  @external_resource @class_diagram

  @moduledoc """
  Jobs API

  ## Resources

  #{File.read!(@class_diagram)}
  """

  use Ash.Api

  resources do
    registry DataAggregator.Jobs.Registry
  end
end
