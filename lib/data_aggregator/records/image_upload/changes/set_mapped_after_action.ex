defmodule DataAggregator.Records.ImageUpload.Changes.SetMappedAfterAction do
  @moduledoc """
  Calls `DataAggregator.Records.ImageUpload.set_mapped/1` after the action has completed
  to update the state to `:mapped`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &set_mapped/2)
  end

  defp set_mapped(_changeset, image_upload) do
    Logger.debug("Setting image upload to mapped ...")
    ImageUpload.set_mapped(image_upload)
  end
end
