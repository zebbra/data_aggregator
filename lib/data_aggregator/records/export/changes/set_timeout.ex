defmodule DataAggregator.Records.Changes.SetTimeout do
  @moduledoc """
  Timeout for the export action. In `DataAggregator.Records.export_timeout/0` you can see how to change various export configurations.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = Records.export_timeout()
    Logger.info("Export timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
