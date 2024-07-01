defmodule DataAggregator.Records.Import.Changes.SetTimeout do
  @moduledoc """
  Sets the timeout for the action based.

  See `DataAggregator.Records.import_timeout/0` for how to set the timeout.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = DataAggregator.Records.import_timeout()
    Logger.debug("Import timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
