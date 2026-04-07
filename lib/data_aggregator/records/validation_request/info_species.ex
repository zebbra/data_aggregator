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
  @spec notify(ValidationRequest.t(), Ash.Query.t(), pos_integer()) ::
          {:ok, ValidationRequest.t()} | {:error, any()}
  def notify(validation_request, query, count) do
    with {:ok, validation_request} <- Ash.load(validation_request, [:collection, :attachment]),
         {:ok, institution_name} <-
           get_institution_name(validation_request.collection.grscicoll_institution_key) do
      notification =
        %{
          count: to_string(count),
          file_link: Attachment.Helpers.attachment_public_url(validation_request.attachment.id),
          institution: institution_name,
          date: get_date_time(),
          owner: institution_name,
          center: validation_request.center,
          collection_code: validation_request.collection.code
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
    "This automatic email is reaching the #{notification.center} centre either because there are new records available for validation or because the original data has been updated for the dataset #{notification.collection_code} of the #{notification.institution}. \n\n" <>
      "Number of records in the requested validation: #{notification.count} \n" <>
      "Time stamp of the requested validation: #{notification.date} \n\n" <>
      "Link to download the dataset: #{notification.file_link} \n\n" <>
      "Please follow the conventions established with GBIF.ch to ensure smooth data flow.\n\n" <>
      "Regards,\n" <>
      "The GBIF.ch team"
  end

  @spec notify_infospecies(Ash.Query.t(), map()) :: :ok
  defp notify_infospecies(query, notification) do
    Logger.debug("Notifying infospecies center: #{inspect(notification)}")

    {:ok, to_mails} = InfospeciesCenters.get_center_emails(notification.center)

    case new()
         |> from(System.get_env("MAILBOX_FROM") || "museums.tovalidate@gbif.ch")
         |> to(to_mails)
         |> subject("DAGI: New requested validation for #{notification.collection_code}")
         |> text_body(get_message_body(notification))
         |> Mailer.deliver() do
      {:ok, result} ->
        Logger.info(
          "[Validation request infospecies center notification] Mail sent successful with result: #{inspect(result)}"
        )

      {:error, error} ->
        Logger.error(
          "[Validation request infospecies center notification] Mail sending failed with error: #{inspect(error)}"
        )
    end

    if Records.execute_async?() do
      Task.start(fn -> update_records_validation_started_at(query) end)
    else
      update_records_validation_started_at(query)
    end

    :ok
  end

  defp update_records_validation_started_at(query) do
    # Use bulk_update instead of N individual updates.
    # Cap batch_size to 100 to stay within PG's 65535 parameter limit
    # (Record has ~280 attributes tracked by PaperTrail).
    tenant = query.tenant

    query
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000)
    |> Ash.bulk_update!(:update_last_validation_started_at, %{},
      resource: Record,
      batch_size: 100,
      authorize?: false,
      domain: Records,
      tenant: tenant,
      return_errors?: true
    )
  end

  defp get_date_time do
    DateTime.utc_now()
    |> DateTime.shift_zone!("Europe/Zurich")
    |> Cldr.DateTime.to_string!(format: :short)
  end
end
