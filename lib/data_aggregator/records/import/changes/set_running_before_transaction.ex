defmodule DataAggregator.Records.Import.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.before_transaction(&set_running/1)
  end

  defp set_running(%Changeset{data: import} = changeset) do
    case Import.set_running(import) do
      {:ok, import} ->
        %Changeset{changeset | data: import}

      {:error, reason} ->
        changeset |> Changeset.add_error(reason)
    end
  end
end
