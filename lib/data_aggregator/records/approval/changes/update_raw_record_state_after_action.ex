defmodule DataAggregator.Records.Approval.Changes.UpdateRawRecordStateAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Approval.set_done/1` after the action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_approved/2)
  end

  defp set_approved(_changeset, approved_record) do
    approved_record = Records.load!(approved_record, [:record], lazy?: true)

    Record.update_approval_status!(approved_record.record, :approved)

    {:ok, approved_record}
  end
end
