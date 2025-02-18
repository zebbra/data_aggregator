defmodule DataAggregator.Records.ValidationStatusType do
  @moduledoc """
  Enum to define the states a record can be in for Validation.
  """

  use Ash.Type.Enum,
    values: [
      :not_validated,
      :validating,
      :in_validation,
      :validated,
      :validation_failed,
      :stale
    ]
end
