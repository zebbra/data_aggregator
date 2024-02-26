defmodule DataAggregator.Records.ChangeEvent.EventCategory do
  @moduledoc """
  Enum to define the categories which can be used on a `DataAggregator.Records.ChangeEvent` of a change event.
  """

  use Ash.Type.Enum, values: [:encoding, :import]
end
