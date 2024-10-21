defmodule DataAggregator.Records.ImageUpload.Changes.MapImages do
  @moduledoc """
  Changeset hook to map images from the image upload to the collections records.
  """
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &map_images(&1, ctx))
  end

  defp map_images(%Changeset{data: image_upload} = changeset, %{actor: actor} = _ctx) do
    Logger.info("Mapping images for #{inspect(image_upload.id)} ...")

    image_upload =
      Ash.load!(image_upload, images: :attachment, collection: :records)

    Enum.each(image_upload.images, fn image ->
      case Enum.find(
             image_upload.collection.records,
             &matching_record?(&1, image, image_upload.mapping_identifier)
           ) do
        nil ->
          Logger.info("No record found for image #{image.attachment.filename}")

        matching_record ->
          Logger.info("Record found for image #{image.attachment.filename}")

          Record.add_image(matching_record, image, actor: actor)
      end
    end)

    changeset
  end

  defp matching_record?(record, image, identifier) do
    parts = String.split(image.attachment.filename, "_")
    # incase the there is no - in the name split for the .
    parts = parts |> List.first() |> String.split(".")
    List.first(parts) == Map.get(record, identifier)
  end
end
