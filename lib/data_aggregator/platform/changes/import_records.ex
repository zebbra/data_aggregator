defmodule DataAggregator.Platform.Changes.ImportRecords do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
  end
end
