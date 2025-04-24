defmodule DataAggregator.Records.ValidationResponse.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ValidationResponse

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: validation_response} = changeset) do
    case ValidationResponse.set_running(validation_response) do
      {:ok, validation_response} ->
        %{changeset | data: validation_response}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
