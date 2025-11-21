defmodule DataAggregator.Files.Workers.AttachmentDeleter do
  @moduledoc """
    `Oban.Worker` to perform `DataAggregator.File.Attachment.hard_destroy/1` asynchronously on all priviously soft
    deleted attachments.

    This is triggered by a crontab configured in /configs/config.exs

  """

  use Oban.Worker, queue: :attachment_deletion, max_attempts: 1

  alias DataAggregator.Files.Attachment

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{meta: %{"cron" => true}} = job) do
    Logger.debug("Starting to destroy obsolete Attachments with job #{job.id}")

    result =
      1000
      |> deletable_attachments_stream()
      |> Enum.reduce(%{failed: 0, successful: 0}, fn attachment, acc ->
        case Attachment.hard_destroy(attachment) do
          :ok ->
            Logger.debug("Attachment #{attachment.id} destroyed successfully")

            %{acc | successful: acc.successful + 1}

          {:error, error} ->
            Logger.error("Failed to destroy attachment #{attachment.id}: #{inspect(error)}")

            %{acc | failed: acc.failed + 1}
        end
      end)

    Logger.debug(
      "Finished destroying obsolete Attachments with job #{job.id}. Successful: #{result.successful}, Failed: #{result.failed}"
    )

    :ok
  end

  @spec deletable_attachments_stream(pos_integer()) :: Enumerable.t()
  def deletable_attachments_stream(limit) do
    Attachment
    |> Ash.Query.filter_input(deletable: true)
    |> Ash.Query.limit(limit)
    |> Ash.stream!()
  end

  @impl Oban.Worker
  def timeout(_job), do: to_timeout(minute: 3)
end
