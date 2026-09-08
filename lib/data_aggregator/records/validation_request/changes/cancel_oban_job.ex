defmodule DataAggregator.Records.ValidationRequest.Changes.CancelObanJob do
  @moduledoc """
  Before-action change for `ValidationRequest` destroy that cancels the
  associated Oban job so queued jobs stop and running jobs are interrupted.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &cancel_oban_job/1)
  end

  defp cancel_oban_job(%Changeset{data: %{oban_job_id: nil}} = changeset), do: changeset

  defp cancel_oban_job(%Changeset{data: %{id: id, oban_job_id: job_id}} = changeset) do
    :ok = Oban.cancel_job(job_id)
    Logger.debug("Cancelled Oban job #{job_id} for validation request #{id}")
    changeset
  end
end
