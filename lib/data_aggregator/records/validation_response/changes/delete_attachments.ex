defmodule DataAggregator.Records.ValidationResponse.Changes.DeleteAttachments do
  @moduledoc """
  Deletes attachments associated with the validation response when it's destroyed.

  This ensures that when a validation response is destroyed, its attachment and error_log
  files are propperly cleaned up from the database and s3 storage.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment

  require Logger

  def change(%Changeset{data: validation_response} = changeset, _opts, _ctx) do
    case Ash.load(validation_response, [:attachment, :error_log]) do
      {:ok, loaded_validation_response} ->
        attachments_to_delete =
          Enum.filter(
            [loaded_validation_response.attachment, loaded_validation_response.error_log],
            &(&1 != nil)
          )

        Changeset.after_action(changeset, &delete_attachments(&1, &2, attachments_to_delete))

      {:error, _error} ->
        changeset
    end
  end

  defp delete_attachments(_changeset, validation_response, attachments_to_delete) do
    Enum.each(attachments_to_delete, &delete_attachment/1)
    {:ok, validation_response}
  end

  defp delete_attachment(%Attachment{} = attachment) do
    case Attachment.destroy(attachment) do
      :ok ->
        Logger.debug("Successfuly deleted attachment: #{attachment.id}")

      {:error, error} ->
        Logger.warning("Failed to delete attachment #{attachment.id}: #{inspect(error)}")
    end
  end

  defp delete_attachment(nil), do: :ok
end
