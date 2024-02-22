defmodule DataAggregator.Records.Encoding.EncodingActionResult do
  @moduledoc """
    This module is represents the result of an encoding process
  """
  alias DataAggregator.Records.Record

  @type t :: {:ok, Record.t()} | {:error, any()}
end
