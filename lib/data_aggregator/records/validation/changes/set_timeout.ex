defmodule DataAggregator.Records.Validation.Changes.SetTimeout do
  @moduledoc """
  Timeout for the validation action. In `DataAggregator.Records.validation_timeout/0` you can see how to change various configurations.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = Records.validation_timeout()

    Logger.info("Validation timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
