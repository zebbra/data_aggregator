defmodule DataAggregator.Records.Publication.Changes.SetPublishedAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Publication.set_published/1` after the publication action
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Publication

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_published/2)
  end

  defp set_published(_changeset, publication) do
    Publication.set_published(publication)
  end
end
