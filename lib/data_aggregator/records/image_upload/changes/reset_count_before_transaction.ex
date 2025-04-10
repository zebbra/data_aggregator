defmodule DataAggregator.Records.ImageUpload.Changes.ResetCountBeforeTransaction do
  @moduledoc """
  Sets `:general_mapping_progress_count`, `:unmapped_images_count` and `:mapped_images_count` to `0` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &reset_count/1)
  end

  defp reset_count(%Changeset{data: image_upload} = changeset) do
    with {:ok, image_upload} <-
           ImageUpload.update(image_upload, %{general_mapping_progress_count: 0}),
         {:ok, image_upload} <- ImageUpload.update(image_upload, %{unmapped_images_count: 0}),
         {:ok, image_upload} <- ImageUpload.update(image_upload, %{mapped_images_count: 0}) do
      %{changeset | data: image_upload}
    else
      {:error, reason} ->
        Logger.error("Error while resetting image upload counts: #{inspect(reason)}")
        Changeset.add_error(changeset, reason)
    end
  end
end
