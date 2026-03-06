defmodule DataAggregator.Records.Publication.Scheduler.PublicationVerifier do
  @moduledoc """
  checks in a fixed interval if a record has been published on the gbif portal

  if the record has not been published, it will check again in the next interval

  ## Arguments

  * `id` - the ID of the record to check on the gbif portal
  * `collection_id` - the ID of the collection the record belongs to

  """
  use Oban.Worker, queue: :publication_verifications, max_attempts: 3

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
  def perform(%Oban.Job{
        max_attempts: max_attempts,
        attempt: attempt,
        args: %{"id" => id, "collection_id" => collection_id, "user_id" => user_id}
      }) do
    actor =
      case User.get_by_id(user_id) do
        {:ok, user} -> user
        {:error, _} -> nil
      end

    perform_check(id, collection_id, actor, attempt, max_attempts)
  rescue
    e ->
      record = Record.get_by_id!(id, tenant: collection_id)

      Logger.error(Exception.format(:error, e, __STACKTRACE__))

      maybe_queue_again(attempt, max_attempts, record)
  end

  @impl Oban.Worker
  def backoff(_), do: publication_interval_minutes()

  @impl Oban.Worker
  def timeout(_job), do: to_timeout(hour: 1)

  defp perform_check(id, collection_id, actor, attempt, max_attempts) do
    record = Record.get_by_id!(id, tenant: collection_id)

    result = Record.check_if_published(record, actor: actor, authorize?: false)

    case result do
      {:ok, record} ->
        if record.publication_status == :published do
          {:ok, record}
        else
          maybe_queue_again(attempt, max_attempts, record)
        end

      {:error, error} ->
        Logger.warning(inspect(error))

        maybe_queue_again(attempt, max_attempts, record)
    end
  end

  defp maybe_queue_again(attempt, max_attempts, record) do
    if attempt < max_attempts && scheduler_active?() do
      Logger.debug("Record #{record.id} has not been published to GBIF. We queue it to check again.")

      {:error, nil}
    else
      Logger.debug("#{record.id} still not published on GBIF on the last attempt. set publication status to failed.")

      Record.update_publication_status(record, :publication_failed)
      :ok
    end
  end

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
