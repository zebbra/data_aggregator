defmodule DataAggregator.Records.Encoding.Changes.AddImageUrl do
  @moduledoc """
  Changeset hook to add image url to encoded records associated media.
  """

  use Ash.Resource.Change

  import DataAggregator.Records.ImageUpload.Helpers, only: [construct_image_url: 2]

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, %{actor: actor} = ctx) do
    Changeset.before_action(changeset, &add_image(&1, ctx), actor: actor)
  end

  defp add_image(%Changeset{arguments: %{image: image}} = changeset, _ctx) do
    Logger.info("Adding image url to encoded record ...")

    associated_media = Changeset.get_attribute(changeset, :mte_associated_media) || ""
    collection_id = Changeset.get_attribute(changeset, :collection_id)
    image_url = construct_image_url(collection_id, image.id)

    if String.contains?(associated_media, image_url) do
      Logger.info("Image already in mte_associated_media on encoded record.")
      changeset
    else
      Logger.info("Adding image to mte_associated_media on encoded record.")

      Changeset.force_change_attribute(
        changeset,
        :mte_associated_media,
        maybe_concatenate(associated_media, image_url)
      )
    end
  end

  defp maybe_concatenate(associated_media, new_url) do
    case associated_media do
      "" -> new_url
      _ -> "#{associated_media} | #{new_url}"
    end
  end
end
