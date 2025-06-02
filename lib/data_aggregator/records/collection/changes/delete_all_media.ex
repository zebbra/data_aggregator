defmodule DataAggregator.Records.Collection.Changes.DeleteAllMedia do
  @moduledoc """
  Deletes all media files associated with the collection and its records.

  This is necessary due to the fact that the media files are stored in s3 and can not be deleted
  by referential integrity over the database. This change ensures that all media files/attachments are deleted
  after the collection is deleted successfully.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationResponse

  require Logger

  def change(%Changeset{data: collection} = changeset, _opts, _ctx) do
    attachments_to_delete = collect_media_files(collection)

    Changeset.after_action(changeset, &delete_media_files(&1, &2, attachments_to_delete))
  end

  # collect all media from the given collection and delete it
  defp collect_media_files(collection) do
    [
      collect_records_media(collection) ++
        collect_imports_media(collection) ++
        collect_exports_media(collection) ++
        collect_publications_media(collection) ++
        collect_validation_requests_media(collection) ++
        collect_validation_responses_media(collection) ++
        collect_image_uploads_media(collection)
    ]
    |> List.flatten()
    |> Enum.filter(fn attachment ->
      case attachment do
        %Attachment{} -> true
        _ -> false
      end
    end)
  end

  defp collect_records_media(collection) do
    Record
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:image_attachments])
    |> Enum.map(fn record ->
      record.image_attachments
    end)
  end

  defp collect_imports_media(collection) do
    Import
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:attachment, :error_log])
    |> Enum.map(fn import ->
      [import.attachment, import.error_log]
    end)
  end

  defp collect_exports_media(collection) do
    Export
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:attachment])
    |> Enum.map(fn export ->
      export.attachment
    end)
  end

  defp collect_publications_media(collection) do
    Publication
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:attachment])
    |> Enum.map(fn import ->
      import.attachment
    end)
  end

  defp collect_validation_requests_media(collection) do
    ValidationRequest
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:attachment])
    |> Enum.map(fn validation_request ->
      validation_request.attachment
    end)
  end

  defp collect_validation_responses_media(collection) do
    ValidationResponse
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:attachment, :error_log])
    |> Enum.map(fn validation_response ->
      [
        validation_response.attachment,
        validation_response.error_log
      ]
    end)
  end

  defp collect_image_uploads_media(collection) do
    ImageUpload
    |> Ash.Query.set_tenant(collection)
    |> Ash.stream!(load: [:attachment, :upload_log, :image_attachments])
    |> Enum.map(fn image_upload ->
      [image_upload.attachment, image_upload.upload_log] ++
        image_upload.image_attachments
    end)
  end

  defp delete_media_files(_changeset, collection, attachments_to_delete) do
    Enum.each(attachments_to_delete, fn attachment ->
      delete_attachment(attachment)
    end)

    {:ok, collection}
  end

  defp delete_attachment(nil), do: :ok

  defp delete_attachment(attachment) do
    Attachment.destroy!(attachment)

    :ok
  end

  # test and ship!!
end
