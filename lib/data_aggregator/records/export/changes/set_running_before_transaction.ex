defmodule DataAggregator.Records.Export.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Export

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: export} = changeset) do
    case Export.set_running(export) do
      {:ok, export} ->
        %{changeset | data: export}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
