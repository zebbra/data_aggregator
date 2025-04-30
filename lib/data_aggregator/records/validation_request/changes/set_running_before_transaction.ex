defmodule DataAggregator.Records.ValidationRequest.Changes.SetRunningBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ValidationRequest

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_running/1)
  end

  defp set_running(%Changeset{data: validation_request} = changeset) do
    case ValidationRequest.set_running(validation_request) do
      {:ok, validation_request} ->
        %{changeset | data: validation_request}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
