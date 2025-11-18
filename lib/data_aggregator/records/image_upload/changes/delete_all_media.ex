defmodule DataAggregator.Records.ImageUpload.Changes.DeleteAllMedia do
  @moduledoc """
  Deletes all media files associated with the image_upload.

  This is necessary due to the fact that the media files are stored in s3 and can not be deleted
  by referential integrity over the database. This change ensures that all media files/attachments are deleted
  after the image_upload is deleted successfully.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Record.Image

  require Ash.Query
  require Logger

  @impl true
  def change(%Changeset{data: image_upload} = changeset, _opts, _ctx) do
    image_upload =
      Ash.load!(image_upload, [:attachment, :upload_log, :image_attachments, :images], lazy?: true)

    attachments_to_delete = collect_media_files(image_upload)

    images = Ash.load!(image_upload.images, [:image_url, record: :encoded_record])

    Changeset.after_action(
      changeset,
      &delete_media_files(&1, &2, attachments_to_delete, images)
    )
  end

  @impl true
  def after_batch(changesets_and_results, _opts, _context) do
    Enum.each(changesets_and_results, fn {_changeset, attachment} ->
      delete_attachment(attachment)
    end)

    :ok
  end

  defp collect_media_files(image_upload) do
    image_upload
    |> collect_attachments()
    |> Enum.filter(fn attachment ->
      case attachment do
        %Attachment{} -> true
        _ -> false
      end
    end)
  end

  defp collect_attachments(image_upload) do
    List.flatten(image_upload.image_attachments ++ [image_upload.attachment, image_upload.upload_log])
  end

  defp delete_media_files(_changeset, image_upload, attachments_to_delete, images) do
    Enum.each(attachments_to_delete, fn attachment ->
      delete_attachment(attachment)
    end)

    Enum.each(images, fn image ->
      delete_image(image)
    end)

    {:ok, image_upload}
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

  defp delete_image(nil), do: :ok

  defp delete_image(%Image{} = image) do
    Image.destroy!(image)

    :ok
  end

  defp delete_image(_), do: :ok
end
