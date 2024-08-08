defmodule DataAggregator.Records.Publication.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Publication

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: publication} = changeset) do
    case Publication.set_running(publication) do
      {:ok, publication} ->
        %Changeset{changeset | data: publication}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
