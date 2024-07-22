defmodule DataAggregator.Records.Approval.Changes.SetTimeout do
  @moduledoc """
  Timeout for the approval action. In `DataAggregator.Records.approval_timeout/0` you can see how to change various configurations.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = Records.approval_timeout()

    Logger.info("Approval timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
