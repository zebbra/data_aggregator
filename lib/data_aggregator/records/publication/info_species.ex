defmodule DataAggregator.Records.Publication.InfoSpecies do
  @moduledoc """
  Handles the preparation and exchange of data towards infospecies centers
  """

  import Swoosh.Email

  alias DataAggregator.Gbif
  alias DataAggregator.Mailer
  alias DataAggregator.Records
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

  require Logger

  @spec notify(Publication.t(), Ash.Query.t()) :: {:ok, Publication.t()} | {:error, any()}
  def notify(%Publication{channel: :validation} = publication, query) do
    with {:ok, publication} <- Ash.load(publication, [:collection, :attachment]),
         {:ok, institution_name} <-
           get_institution_name(publication.collection.grscicoll_institution_key) do
      notification =
        %{
          count: to_string(Ash.count!(query)),
          dwca_file_link: publication.attachment.url,
          institution: institution_name,
          date: get_date_time_now(),
          # for now we use institution_name as owner, because we don't have this
          # on the grscicoll collection
          owner: institution_name,
          center: publication.center
        }

      notify_infospecies(query, notification)

      {:ok, publication}
    else
      {:error, error} ->
        Logger.error("Error notifying infospecies center: #{inspect(error)}")

        {:error, error}
    end
  end

  def notify(_publication, _query), do: {:error, "Channel has to be :validation to be published to infospecies"}

  @spec get_institution_name(String.t()) :: {:ok, String.t()}
  defp get_institution_name(nil), do: {:ok, "Unknown institution"}

  defp get_institution_name(key) do
    case Gbif.RestAPI.get_grscicoll_entity(key, :institution) do
      {:ok, institution} ->
        {:ok, Map.get(institution, "code", "") <> " - " <> Map.get(institution, "name", "")}

      {:error, _error} ->
        Logger.debug("Error fetching institution with key: #{key}")
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
      ", link: " <> notification.dwca_file_link
  end

  @spec notify_infospecies(Ash.Query.t(), map()) :: :ok
  defp notify_infospecies(query, notification) do
    Logger.info("Notifying infospecies center: #{inspect(notification)}")

    {:ok, _to_mails} = InfospeciesCenters.get_center_emails(notification.center)

    email =
      new()
      |> from(System.get_env("MAILBOX_FROM") || "museums.tovalidate@gbif.ch")
      # |> to(to_mails) TODO: uncomment this line (and remove the next one) if you
      #    want to send the email to the infospecies centers directly
      |> to(["data@gbif.ch"])
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
