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

      to_mails = Enum.map(users, & &1.email)

      new()
      |> from(System.get_env("MAILBOX_FROM") || "museums.tovalidate@gbif.ch")
      |> to(to_mails)
      |> subject("Dagi: Your Dataset became validated data")
      |> text_body(get_message_body(collection, validation.type))
      |> Mailer.deliver()
    end)

    :ok
  end

  defp get_message_body(collection, :validated) do
    "Hi,\n" <>
      "We reach out to you because your data in the GBIF Dagi project has been updated.\n" <>
      "Multiple records were annotated with reasons why they were not validated.\n" <>
      "Your original data remained unchanged.\n" <>
      "The affected collection '#{collection.code} - #{collection.name}' " <>
      "of institution '#{collection.grscicoll_institution_name}' can be seen here: " <>
      System.get_env("BASE_URL") <> "/datasets/#{collection.id}/records"
  end

  defp get_message_body(collection, :not_validated) do
    "Hi,\n" <>
      "We reach out to you because your data in the GBIF Dagi project has been updated.\n" <>
      "Multiple records were annotated with reasons why they were not validated.\n" <>
      "Your original data remained unchanged.\n" <>
      "The affected collection '#{collection.code} - #{collection.name}' " <>
      "of institution '#{collection.grscicoll_institution_name}' can be seen here: " <>
      System.get_env("BASE_URL") <> "/datasets/#{collection.id}/records"
  end
end
