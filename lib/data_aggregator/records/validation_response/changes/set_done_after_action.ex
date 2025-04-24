defmodule DataAggregator.Records.ValidationResponse.Changes.SetDoneAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.ValidationResponse.set_done/1` after the action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ValidationResponse

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_done/2)
  end

  defp set_done(_changeset, validation_response) do
    ValidationResponse.set_done(validation_response)
  end
end
