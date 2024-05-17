defmodule DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier do
  @moduledoc """
  checks in a fixed interval if a record has been published on the gbif portal

  if the record has not been pubished, it will check again in the next interval

  ## Arguments

  * `id` - the ID of the record to check on the gbif portal

  """

  use Oban.Worker, queue: :publication_verification, max_attempts: 10

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  require Logger

  @one_day 60 * 60 * 24

  @impl true
  def perform(%Oban.Job{args: %{"id" => id}} = args) do
    record = id |> Record.get_by_id!() |> Record.check_if_fast_track_pubished!()

    if record.fast_track_status != :published do
      args
      |> new(schedule_in: @one_day)
      |> Oban.insert!()
    else
      Logger.warning("Record #{record.id} has been published on GBIF already. We don't queue it again.")
    end

    {:ok, record}
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.export_timeout() + :timer.minutes(1)
end
