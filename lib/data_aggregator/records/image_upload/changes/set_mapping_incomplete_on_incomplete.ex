defmodule DataAggregator.Records.ImageUpload.Changes.SetMappingIncompleteOnIncomplete do
  @moduledoc """
  Sets the state to `:incomplete` if the mapping could not map all images.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &maybe_set_incomplete/2)
  end

  defp maybe_set_incomplete(_changeset, image_upload) do
    if image_upload.unmapped_images_count > 0 do
      Logger.debug("Setting image upload to incomplete ...")
      ImageUpload.set_mapping_incomplete(image_upload)
    else
      {:ok, image_upload}
    end
  end
end
