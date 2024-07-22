defmodule DataAggregator.Records.ApprovalStatusType do
  @moduledoc """
  Enum to define the states a record can be in for Approval.
  """

  use Ash.Type.Enum,
    values: [
      :not_approved,
      :approving,
      :in_approval,
      :approved,
      :approval_failed,
      :stale
    ]
end
