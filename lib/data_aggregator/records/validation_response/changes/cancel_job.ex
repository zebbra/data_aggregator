defmodule DataAggregator.Records.ValidationResponse.Changes.CancelJob do
  @moduledoc """
  Cancel the Oban job associated with this validation response, if any.
  """
  use Ash.Resource.Change

  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Collection.Changes.CancelAction

  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    query = Job.query_to_validation_response_by_id(changeset.data.id)
    {:ok, number} = CancelAction.cancel_all_jobs(query)
    Logger.info("Cancelled #{number} Oban jobs for ValidationResponse #{changeset.data.id}")

    changeset
  end
end
