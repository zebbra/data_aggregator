defmodule DataAggregator.Records.Encoding.Changes.AddImageUrl do
  @moduledoc """
  Changeset hook to add image url to encoded records associated media.
  """

  use Ash.Resource.Change

  import DataAggregator.Records.ImageUpload.Helpers,
    only: [construct_image_url: 2, construct_associated_media: 2]

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

    new_associated_media = construct_associated_media(associated_media, image_url)

    if new_associated_media == associated_media do
      changeset
    else
      Changeset.force_change_attribute(
        changeset,
        :mte_associated_media,
        new_associated_media
      )
    end
  end
end
