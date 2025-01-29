defmodule DataAggregator.Records.ImageUpload.Changes.MapImages do
  @moduledoc """
  Changeset hook to map images from the image upload to the collections records.
  """
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &map_images(&1, ctx))
  end

  defp map_images(%Changeset{data: image_upload} = changeset, ctx) do
    Logger.info("Mapping images for #{inspect(image_upload.id)} ...")

    image_upload =
      Ash.load!(image_upload, [:collection, images: :attachment], lazy?: true)

    Record
    |> Ash.Query.set_tenant(image_upload.collection)
    |> Ash.Query.filter(collection_id == ^image_upload.collection_id)
    |> Ash.stream!()
    |> Enum.each(fn record ->
      Enum.each(
        image_upload.images,
        &search_for_matching_image(record, &1, image_upload.mapping_identifier, ctx)
      )
    end)

    changeset
  end

  @spec matching_image?(Record.t(), Record.Image.t(), String.t()) ::
          {boolean, Record.Image.t()}
  defp matching_image?(record, image, identifier) do
    parts = String.split(image.attachment.filename, "_")
    # incase the there is no - in the name split for the .
    part_to_match =
      if length(parts) == 1 do
        parts
        |> List.first()
        |> String.split(".")
        # remove the file extension
        |> List.delete_at(-1)
        |> Enum.join(".")
      else
        List.first(parts)
      end

    {part_to_match == Map.get(record, identifier), image}
  end

  @spec search_for_matching_image(Record.t(), Record.Image.t(), String.t(), map()) :: :ok
  defp search_for_matching_image(record, image, identifier, %{actor: actor, tenant: tenant} = _ctx) do
    case matching_image?(record, image, identifier) do
      {true, image} ->
        Logger.debug("Record found for image #{image.attachment.filename}")

        Record.add_image(record, image,
          actor: actor,
          authorize?: false,
          tenant: tenant
        )

      _ ->
        Logger.debug("No record found for image #{image.attachment.filename}")
    end

    :ok
  end
end
