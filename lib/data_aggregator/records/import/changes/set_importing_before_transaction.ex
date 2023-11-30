defmodule DataAggregator.Records.Import.Changes.SetImportingBeforeTransaction do
  @moduledoc """
  Sets the state to `:running` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import

  require Logger

  # def change(%Changeset{phase: :validate} = changeset, _opts, _ctx) do
  #   # fake transition so validation doesn't fail
  #   put_in(changeset.data.state, :importing)
  #   |> Changeset.before_transaction(&set_importing/1)
  # end

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_importing/1)
  end

  defp set_importing(%Changeset{data: import} = changeset) do
    case Import.set_importing(import) do
      {:ok, import} ->
        %Changeset{changeset | data: import}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
