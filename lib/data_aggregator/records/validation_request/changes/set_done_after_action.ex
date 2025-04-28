defmodule DataAggregator.Records.ValidationRequest.Changes.SetDoneAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.ValidationRequest.set_done/1` after the validation request action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ValidationRequest

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_done/2)
  end

  defp set_done(_changeset, publication) do
    ValidationRequest.set_done(publication)
  end
end
