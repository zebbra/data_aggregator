defmodule DataAggregator.Records.Record.Changes.AddImages do
  @moduledoc """
  Changeset hook to add images to a record. This will manage relationship to Images.
  And start change on encoded record to update associated media.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.EncodedRecord

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &add_images(&1, ctx))
  end

  defp add_images(
         %Changeset{arguments: %{images: images}, data: record} = changeset,
         %{actor: actor, tenant: tenant} = _ctx
       ) do
    changeset = Changeset.manage_relationship(changeset, :images, images, type: :append)

    encoded_record =
      case record.encoded_record do
        %Ash.NotLoaded{} -> EncodedRecord.get_by_record!(record.id, tenant: tenant)
        encoded_record -> encoded_record
      end

    _encoded_record_with_images =
      Enum.reduce(images, encoded_record, fn image, encoded_record ->
        EncodedRecord.add_image_url!(encoded_record, image, actor: actor)
      end)

    changeset
  end
end
