defmodule DataAggregator.Records.Validation.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Validation

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: validation} = changeset) do
    case Validation.set_running(validation) do
      {:ok, validation} ->
        %{changeset | data: validation}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
