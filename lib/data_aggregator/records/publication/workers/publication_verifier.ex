defmodule DataAggregator.Records.Publication.Scheduler.PublicationVerifier do
  @moduledoc """
  checks in a fixed interval if a record has been published on the gbif portal

  if the record has not been pubished, it will check again in the next interval

  ## Arguments

  * `id` - the ID of the record to check on the gbif portal

  """

  use Oban.Worker, queue: :publication_verification, max_attempts: 10

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  @one_day 60 * 60 * 24

  @impl true
  def perform(%Oban.Job{args: %{"id" => id}} = args) do
    # TODO: implement this and make test
    record = Record.check_if_fast_track_pubished!(id)

    if record.fast_track_status != :published do
      args
      |> new(schedule_in: @one_day)
      |> Oban.insert!()
    end

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.export_timeout() + :timer.minutes(1)
end
