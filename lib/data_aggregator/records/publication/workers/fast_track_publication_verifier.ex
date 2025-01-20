defmodule DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier do
  @moduledoc """
  checks in a fixed interval if a record has been published on the gbif portal

  if the record has not been pubished, it will check again in the next interval

  ## Arguments

  * `id` - the ID of the record to check on the gbif portal
  * `collection_id` - the ID of the collection the record belongs to

  """
  use Oban.Worker, queue: :publication_verifications, max_attempts: 10

  alias __MODULE__
  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Record

  require Logger

  defp scheduler_active?,
    do: Application.get_env(:data_aggregator, :publication_verification_scheduler_active, true) === true

  # the seconds of one day
  @minute 60
  @hour 60 * @minute
  @day 24 * @hour

  @impl true
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id, "user_id" => user_id}}) do
    actor =
      case User.get_by_id(user_id) do
        {:ok, user} -> user
        {:error, _} -> nil
      end

    record =
      id
      |> Record.get_by_id!(tenant: collection_id)
      |> Record.check_if_fast_track_pubished!(actor: actor, authorize?: false)

    if scheduler_active?() && record.fast_track_status != :published do
      %{id: id, collection_id: collection_id, user_id: user_id}
      |> FastTrackPublicationVerifier.new(schedule_in: publication_interval_minutes())
      |> Oban.insert!()

      Logger.debug("Record #{record.id} has not been published to GBIF. We queue it to check again.")
    else
      Logger.debug("Record #{record.id} has been published on GBIF already. We don't queue it again.")
    end

    {:ok, record}
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.hours(1)

  # gives us the interval for the next job to be executed, in seconds
  defp publication_interval_minutes do
    publication_interval_minutes = System.get_env("PUBLICATION_VERIFY_JOB_SCHEDULE_MINUTES")

    if publication_interval_minutes do
      Logger.debug("Setting publication verification job interval to #{publication_interval_minutes} minutes")

      # we wanna have seconds so, we multiply with 60
      String.to_integer(publication_interval_minutes) * 60
    else
      Logger.debug("Setting publication verification job interval to #{@day} minutes")

      @day
    end
  end
end
