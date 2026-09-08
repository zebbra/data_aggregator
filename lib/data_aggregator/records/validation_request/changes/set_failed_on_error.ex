defmodule DataAggregator.Records.ValidationRequest.Changes.SetFailedOnError do
  @moduledoc """
  Sets the state to `:failed` if the transaction fails.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ValidationRequest

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &handle_error/2)
  end

  defp handle_error(_changeset, {:ok, vr}) do
    {:ok, vr}
  end

  defp handle_error(%Changeset{data: vr}, {:error, error}) do
    Logger.warning("ValidationRequest error: #{inspect(error)}")
    ValidationRequest.set_failed(vr)
  end
end
