defmodule DataAggregator.Records.Record.Image.Changes.RemoveAssociatedMedia do
  @moduledoc """
  Deletes all media files associated with the image_upload.

  This is necessary due to the fact that the media files are stored in s3 and can not be deleted
  by referential integrity over the database. This change ensures that all media files/attachments are deleted
  after the image_upload is deleted successfully.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.EncodedRecord

  require Ash.Query
  require Logger

  def change(%Changeset{data: image} = changeset, _opts, _ctx) do
    image = Ash.load!(image, [:image_url, :attachment, record: :encoded_record])

    Changeset.after_action(
      changeset,
      &remove_obsolete_image_url(&1, &2, image)
    )
  end

  defp remove_obsolete_image_url(_changeset, _deleted_image, image) do
    old_media_urls =
      case image.record.encoded_record.mte_associated_media do
        nil -> ""
        urls -> urls
      end

    updated_media_urls =
      old_media_urls
      |> String.split(" | ")
      |> Enum.reject(fn url ->
        url == image.image_url
      end)
      |> Enum.join(" | ")

    EncodedRecord.update!(image.record.encoded_record, %{mte_associated_media: updated_media_urls})

    delete_attachment(image.attachment)

    {:ok, image}
  end

  defp delete_attachment(nil), do: :ok

  defp delete_attachment(%Attachment{} = attachment) do
    case Attachment.get_by_id(attachment.id) do
      {:ok, attachment} ->
        Attachment.destroy!(attachment)

      {:error, error} ->
        Logger.info("Error deleting attachment: ID: #{attachment.id}, Error: #{inspect(error)}")
    end

    :ok
  end

  defp delete_attachment(_), do: :ok
end
