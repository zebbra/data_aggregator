defmodule DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier do
  @moduledoc """
  checks in a fixed interval if a record has been published on the gbif portal

  if the record has not been pubished, it will check again in the next interval

  ## Arguments

  * `id` - the ID of the record to check on the gbif portal

  """
  use Oban.Worker, queue: :publication_verification, max_attempts: 10, unique: [period: one_day()]

  alias DataAggregator.Records.Record

  require Logger

  @one_day 1 * 60 * 60 * 24

  defp one_day, do: @one_day

  @impl true
  def perform(%Oban.Job{args: %{"id" => id}}) do
    record = id |> Record.get_by_id!() |> Record.check_if_fast_track_pubished!()

    if record.fast_track_status != :published do
      %{id: id}
      |> new(schedule_in: interval())
      |> Oban.insert!()

      Logger.debug("Record #{record.id} has been published on GBIF already. We don't queue it again.")
    end

    {:ok, record}
  end

  def cancel_job(nil) do
    Logger.debug("No job to cancel")
  end

  def cancel_job(id) do
    Oban.cancel_job(__MODULE__, id)
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.hours(1)

  # gives us the interval for the next job to be executed, in seconds
  defp interval do
    interval = System.get_env("PUBLICATION_VERIFY_JOB_SCHEDULE_MINUTES")

    if interval do
      Logger.debug("Setting publication verification job interval to #{interval} minutes")

      # we wanna have seconds so, we multiply with 60
      String.to_integer(interval) * 60
    else
      Logger.debug("Setting publication verification job interval to #{@one_day} minutes")

      @one_day
    end
  end
end
