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
      |> subject(get_subject(collection.code, validation.type))
      |> text_body(get_message_body(collection, validation.type))
      |> Mailer.deliver()
    end)

    :ok
  end

  defp get_subject(code, :validated),
    do: "DAGI: The validation request has been processed for #{code} - Validated records"

  defp get_subject(code, :not_validated),
    do: "DAGI: The validation request has been processed for #{code} - Not Validated records"

  defp get_message_body(collection, :validated) do
    "--- If you are not responsible for this dataset in your institution, you may ignore this message. ---\n" <>
      "Dear Collection Administrator,\n" <>
      "The dataset #{collection.code} has been updated and the new values from InfoSpecies data centres are available in the validation layer.\n\n" <>
      "Records have been marked as “Validated”.\n" <>
      "Your original data has not been modified.\n" <>
      "You can access the updated dataset #{collection.code} - #{collection.name} " <>
      "of #{collection.grscicoll_institution_name} here: " <>
      System.get_env("BASE_URL") <>
      "/datasets/#{collection.id}/records \n\n" <>
      "Regards,\n\n" <>
      "The DAGI team"
  end

  defp get_message_body(collection, :not_validated) do
    "--- If you are not responsible for this dataset in your institution, you may ignore this message. ---\n" <>
      "Dear Collection Administrator,\n" <>
      "The dataset #{collection.code} has been updated and the feedback from InfoSpecies data centres are available for the concerned records.\n\n" <>
      "Records have been marked as “Not Validated”.\n" <>
      "Your original data has not been modified.\n" <>
      "You can access the updated dataset #{collection.code} - #{collection.name} " <>
      "of #{collection.grscicoll_institution_name} here: " <>
      System.get_env("BASE_URL") <>
      "/datasets/#{collection.id}/records \n\n" <>
      "The status “Not-validated” does not inhibit publication on GBIF.\n\n" <>
      "Regards,\n\n" <>
      "The DAGI team"
  end
end
