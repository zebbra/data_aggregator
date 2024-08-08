defmodule DataAggregator.Records.Publication.Changes.SetDoneAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Publication.set_done/1` after the publication action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Publication

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_done/2)
  end

  defp set_done(_changeset, publication) do
    Publication.set_done(publication)
  end
end
