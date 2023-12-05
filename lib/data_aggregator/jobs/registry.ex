defmodule DataAggregator.Jobs.Registry do
  @moduledoc """
  Registry for `DataAggregator.Jobs` Ash API.
  """

  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Jobs.Job
  end
end
