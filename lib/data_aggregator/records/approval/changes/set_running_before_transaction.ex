defmodule DataAggregator.Records.Approval.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Approval

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: approval} = changeset) do
    case Approval.set_running(approval) do
      {:ok, approval} ->
        %Changeset{changeset | data: approval}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
