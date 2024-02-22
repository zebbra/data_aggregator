defmodule DataAggregator.Records.Encoding.EncodingResultState do
  @moduledoc """
  Enum to define the states which a `DataAggregator.Records.Encoding.RecordEncodingResult` can have.
  """

  use Ash.Type.Enum, values: [:success, :error, :unchanged]
end
