defmodule DataAggregator.Records.Publication.Changes.SetTimeout do
  @moduledoc """
  Timeout for the publish action. In `DataAggregator.Records.export_timeout/0` you can see how to change various export configurations.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = DataAggregator.Records.export_timeout()

    Logger.info("Publication timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
