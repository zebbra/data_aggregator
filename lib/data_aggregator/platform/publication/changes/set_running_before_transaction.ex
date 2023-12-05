defmodule DataAggregator.Platform.Publication.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Publication.Export

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: export} = changeset) do
    case Export.set_running(export) do
      {:ok, export} ->
        %Changeset{changeset | data: export}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
