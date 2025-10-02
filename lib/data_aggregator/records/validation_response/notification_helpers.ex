defmodule DataAggregator.Records.ValidationResponse.NotificationHelpers do
  @moduledoc false

  import Swoosh.Email

  alias Ash.Changeset
  alias DataAggregator.Accounts.User
  alias DataAggregator.Mailer
  alias DataAggregator.Records.ValidationResponse

  require Ash.Query
  require Logger

  @doc """
  Notifies the infospecies team about the result of the validation import
  """
  @spec notify_infospecies(Changeset.t()) :: Changeset.t()
  def notify_infospecies(changeset) do
    notify(changeset.data)

    changeset
  end

  @spec notify(ValidationResponse.t()) :: :ok
  defp notify(validation) do
    Logger.debug("Notifying infospecies about validation result")
    validation = Ash.load!(validation, [:affected_collections], lazy?: true)

    Enum.each(validation.affected_collections, fn collection ->
      {:ok, users} =
        User
        |> Ash.Query.filter(institution_id == ^collection.grscicoll_institution_key)
        |> Ash.Query.filter("collection_administrator" in roles)
        |> Ash.read()

      to_mails = Enum.map(users, &to_string(&1.email))

      new()
      |> from(System.get_env("MAILBOX_FROM") || "museums.tovalidate@gbif.ch")
      |> to(to_mails)
      |> subject("DAGI: New validated data available for #{collection.code}")
      |> text_body(get_message_body(collection, validation.type))
      |> Mailer.deliver()
    end)

    :ok
  end

  defp get_message_body(collection, :validated) do
    "--- If you are not responsible for this dataset in your institution, you may ignore this message. ---\n\n" <>
      "Dear Collection Administrator,\n" <>
      "The dataset #{collection.code} requested for validation to the InfoSpecies data centers in DAGI has now been processed.\n\n" <>
      " - Records that passed validation have been marked as 'Validated'.\n" <>
      " - Records that did not pass validation have been marked as 'Not validated' and annotated accordingly.\n\n" <>
      "Your original data has not been modified. The new validated values are available in the validation layer of the DAGI dataset.\n\n" <>
      "Please note that the 'Not validated' status does not prevent records from being published on GBIF.\n\n" <>
      "You can access the updated dataset #{collection.code} - #{collection.name} " <>
      "of #{collection.grscicoll_institution_name} here: " <>
      System.get_env("BASE_URL") <>
      "/datasets/#{collection.id}/records \n\n" <>
      "Kind regards,\n\n" <>
      "Your DAGI team"
  end

  defp get_message_body(collection, :not_validated) do
    "--- If you are not responsible for this dataset in your institution, you may ignore this message. ---\n\n" <>
      "Dear Collection Administrator,\n" <>
      "The dataset #{collection.code} requested for validation to the InfoSpecies data centers in DAGI has now been processed.\n\n" <>
      " - Records that passed validation have been marked as 'Validated'.\n" <>
      " - Records that did not pass validation have been marked as 'Not validated' and annotated accordingly.\n\n" <>
      "Your original data has not been modified. The new validated values are available in the validation layer of the DAGI dataset.\n\n" <>
      "Please note that the 'Not validated' status does not prevent records from being published on GBIF.\n\n" <>
      "You can access the updated dataset #{collection.code} - #{collection.name} " <>
      "of #{collection.grscicoll_institution_name} here: " <>
      System.get_env("BASE_URL") <>
      "/datasets/#{collection.id}/records \n\n" <>
      "Kind regards,\n\n" <>
      "Your DAGI team"
  end
end
