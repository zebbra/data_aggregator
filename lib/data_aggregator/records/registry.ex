defmodule DataAggregator.Records.Registry do
  @moduledoc """
  Registry for `DataAggregator.Records` Ash API.
  """

  use Ash.Registry,
    extensions: [
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Records.Collection
    entry DataAggregator.Records.Export
    entry DataAggregator.Records.Import
    entry DataAggregator.Records.Import.Record
    entry DataAggregator.Records.Record
    entry DataAggregator.Records.Record.Image
  end
end
