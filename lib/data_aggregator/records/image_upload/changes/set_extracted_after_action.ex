defmodule DataAggregator.Records.ImageUpload.Changes.SetExtractedAfterAction do
  @moduledoc """
  Calls `DataAggregator.Records.ImageUpload.set_extracted/1` after the action has completed
  to update the state to `:extracted`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_extracted/2)
  end

  defp set_extracted(_changeset, image_upload) do
    Logger.debug("Setting image upload to extracted ...")
    ImageUpload.set_extracted(image_upload)
  end
end
