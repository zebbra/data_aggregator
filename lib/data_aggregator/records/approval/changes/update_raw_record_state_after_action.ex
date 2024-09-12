defmodule DataAggregator.Records.Approval.Changes.UpdateRawRecordStateAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Approval.set_done/1` after the action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.after_action(changeset, fn _, approved_record ->
      set_approved(approved_record, ctx)
    end)
  end

  defp set_approved(approved_record, %{actor: actor}) do
    approved_record = Ash.load!(approved_record, [:record], lazy?: true)

    Record.update_approval_status!(approved_record.record, :approved,
      actor: actor,
      authorize?: false
    )

    {:ok, approved_record}
  end
end
