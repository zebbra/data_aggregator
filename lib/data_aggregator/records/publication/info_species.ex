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
  def notify(%Publication{channel: :approval} = publication, query) do
    with {:ok, publication} <- Records.load(publication, [:collection, :attachment]),
         {:ok, institution_name} <-
           get_institution_name(publication.collection.grscicoll_institution_key) do
      notification =
        %{
          count: Records.count!(query),
          dwca_file_link: publication.attachment.url,
          institution: institution_name,
          date: get_date_time_now(),
          owner: institution_name,
          center: publication.center
        }

      # for now we use institution_name as owner, because we don't have this grscicoll collection
      notify_infospecies(query, notification)

      {:ok, publication}
    else
      {:error, error} ->
        Logger.error("Error notifying infospecies center: #{inspect(error)}")

        {:error, error}
    end
  end

  def notify(_publication, _query), do: {:error, "Channel has to be :approval to be published to infospecies"}

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
      notification.dwca_file_link <>
      ", link: " <> notification.count
  end

  @spec notify_infospecies(Ash.Query.t(), map()) :: :ok
  defp notify_infospecies(query, notification) do
    Logger.info("Notifying infospecies center: #{inspect(notification)}")

    {:ok, to_mails} = InfospeciesCenters.get_center_emails(notification.center)

    email =
      new()
      |> from(System.get_env("MAILBOX_FROM"))
      |> to(to_mails)
      |> subject("New records available for approval")
      |> text_body(get_message_body(notification))

    Mailer.deliver(email)

    if Records.execute_async?() do
      Task.start(fn -> update_records_approval_started_at(query) end)
    else
      update_records_approval_started_at(query)
    end

    :ok
  end

  defp update_records_approval_started_at(query) do
    query
    |> Records.stream!(page: false)
    |> Stream.map(&process_record(&1))
    |> Stream.run()
  end

  defp process_record(record) do
    Record.update_last_approval_started_at!(record)
  end

  defp get_date_time_now do
    DateTime.utc_now()
    |> DateTime.shift_zone!("Europe/Zurich")
    |> Cldr.DateTime.to_string!(format: :short)
  end
end
