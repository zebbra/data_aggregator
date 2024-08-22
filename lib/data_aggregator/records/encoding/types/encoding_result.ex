defmodule DataAggregator.Records.Encoding.EncodingResult do
  @moduledoc """
    This module is represents the result of an encoding process
  """
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  @type t :: {:ok, EncodedRecord.t()} | {:error, any(), EncodedRecord.t() | Record.t()}
end
