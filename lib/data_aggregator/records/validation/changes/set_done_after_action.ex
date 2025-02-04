defmodule DataAggregator.Records.Validation.Changes.SetDoneAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Validation.set_done/1` after the action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Validation

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_done/2)
  end

  defp set_done(_changeset, validation) do
    Validation.set_done(validation)
  end
end
