defmodule DataAggregator.Records.ValidationStatusType do
  @moduledoc """
  Enum to define the states a record can be in for Validation.
  """

  use Ash.Type.Enum,
    values: [
      :unknown,
      :requested,
      :validated,
      :not_validated
    ]
end
