defmodule DataAggregator.Records.ValidationResponse.Changes.SetTimeout do
  @moduledoc """
  Timeout for the validation response action. In `DataAggregator.Records.validation_response_timeout/0` you can see how to change various configurations.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = Records.validation_response_timeout()

    Logger.info("Validation response timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
