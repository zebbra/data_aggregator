defmodule DataAggregator.Records.Approval.Changes.SetDoneAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Approval.set_done/1` after the action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Approval

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_done/2)
  end

  defp set_done(_changeset, approval) do
    Approval.set_done(approval)
  end
end
