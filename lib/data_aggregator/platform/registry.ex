defmodule DataAggregator.Platform.Registry do
  @moduledoc """
  Registry for `DataAggregator.Platform` Ash API.
  """

  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Platform.Institution
    entry DataAggregator.Platform.Publication.Consumer
    entry DataAggregator.Platform.Publication.Export
    entry DataAggregator.Platform.Publication.Record
  end
end
