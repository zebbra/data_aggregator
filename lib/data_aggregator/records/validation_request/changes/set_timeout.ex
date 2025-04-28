defmodule DataAggregator.Records.ValidationRequest.Changes.SetTimeout do
  @moduledoc """
  Timeout for the validation request action. In `DataAggregator.Records.validation_request_timeout/0` you can see how to change various export configurations.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = Records.validation_request_timeout()

    Logger.info("ValidationRequest timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
