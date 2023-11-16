defmodule DataAggregator.Records.Import.Changes.SetFailedOnError do
  @moduledoc """
  Sets the state to `:failed` if the transaction fails.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> Changeset.after_transaction(&handle_error/2)
  end

  defp handle_error(_changeset, {:ok, import}) do
    {:ok, import}
  end

  defp handle_error(%Changeset{data: import}, {:error, error}) do
    Logger.error("Import error: #{inspect(error)}")
    Import.set_failed(import)
  end
end
