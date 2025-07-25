defmodule DataAggregator.Records.Import.Changes.SetFailedOnError do
  @moduledoc """
  Sets the state to `:failed` if the transaction fails.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &handle_error/2)
  end

  defp handle_error(_changeset, {:ok, import}) do
    {:ok, import}
  end

  defp handle_error(%Changeset{data: import}, {:error, error}) do
    Logger.warning("Import error: #{inspect(error)}")
    Import.set_failed(import)
  end
end
