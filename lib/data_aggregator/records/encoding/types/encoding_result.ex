defmodule DataAggregator.Records.Encoding.EncodingResult do
  @moduledoc """
    This module is represents the result of an encoding process
  """
  alias DataAggregator.Records.EncodedRecord

  @type t :: {:ok, EncodedRecord.t()} | {:error, any(), EncodedRecord.t()}
end
