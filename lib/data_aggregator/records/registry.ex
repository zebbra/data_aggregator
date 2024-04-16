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
    entry DataAggregator.Records.EncodedRecord
    entry DataAggregator.Records.Encoding.RecordEncodingResult
    entry DataAggregator.Records.Export
    entry DataAggregator.Records.Import
    entry DataAggregator.Records.Import.Record
    entry DataAggregator.Records.Publication
    entry DataAggregator.Records.Record
    entry DataAggregator.Records.Record.Image
    entry DataAggregator.Records.Record.Version
    entry DataAggregator.Records.EncodedRecord.Version
  end
end
