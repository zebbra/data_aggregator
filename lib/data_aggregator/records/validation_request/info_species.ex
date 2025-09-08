defmodule DataAggregator.Records.ValidationRequest.InfoSpecies do
  @moduledoc """
  Handles the preparation and exchange of data towards infospecies centers
  """

  import Swoosh.Email

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Gbif
  alias DataAggregator.Mailer
  alias DataAggregator.Records
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

  require Logger

  @doc """
  Notifies the infospecies center by mail about the validation request.
  """
  @spec notify(ValidationRequest.t(), Ash.Query.t()) ::
          {:ok, ValidationRequest.t()} | {:error, any()}
  def notify(validation_request, query) do
    with {:ok, validation_request} <- Ash.load(validation_request, [:collection, :attachment]),
         {:ok, institution_name} <-
           get_institution_name(validation_request.collection.grscicoll_institution_key) do
      notification =
        %{
          count: to_string(Ash.count!(query)),
          file_link: Attachment.Helpers.attachment_public_url(validation_request.attachment.id),
          institution: institution_name,
          date: get_date_time_now(),
          # for now we use institution_name as owner, because we don't have this
          # on the grscicoll collection
          owner: institution_name,
          center: validation_request.center
        }

      notify_infospecies(query, notification)

      {:ok, validation_request}
    else
      {:error, error} ->
        Logger.error("Error notifying infospecies center: #{inspect(error)}")

        {:error, error}
    end
  end

  @spec get_institution_name(String.t()) :: {:ok, String.t()}
  defp get_institution_name(nil), do: {:ok, "Unknown institution"}

  defp get_institution_name(key) do
    case Gbif.RestAPI.get_grscicoll_entity(key, :institution) do
      {:ok, institution} ->
        {:ok, Map.get(institution, "code", "") <> " - " <> Map.get(institution, "name", "")}

      {:error, _error} ->
        Logger.warning("Error fetching institution with key: #{key}")
        # we swallow the error here, because we don't want to abort the process
        # of notifying the infospecies centers
        {:ok, "Unknown institution"}
    end
  end

  defp get_message_body(notification) do
    "institution: " <>
      notification.institution <>
      "owner: " <>
      notification.owner <>
      ", date: " <>
      notification.date <>
      ", count: " <>
      notification.count <>
      ", link: " <> notification.file_link
  end

  @spec notify_infospecies(Ash.Query.t(), map()) :: :ok
  defp notify_infospecies(query, notification) do
    Logger.debug("Notifying infospecies center: #{inspect(notification)}")

    {:ok, to_mails} = InfospeciesCenters.get_center_emails(notification.center)

    email =
      new()
      |> from(System.get_env("MAILBOX_FROM") || "museums.tovalidate@gbif.ch")
      |> to(to_mails)
      |> subject("New records available for validation")
      |> text_body(get_message_body(notification))

    Mailer.deliver(email)

    if Records.execute_async?() do
      Task.start(fn -> update_records_validation_started_at(query) end)
    else
      update_records_validation_started_at(query)
    end

    :ok
  end

  defp update_records_validation_started_at(query) do
    query
    |> Ash.stream!()
    |> Enum.each(&process_record(&1))
  end

  defp process_record(record) do
    Record.update_last_validation_started_at!(record)
  end

  defp get_date_time_now do
    DateTime.utc_now()
    |> DateTime.shift_zone!("Europe/Zurich")
    |> Cldr.DateTime.to_string!(format: :short)
  end
end
