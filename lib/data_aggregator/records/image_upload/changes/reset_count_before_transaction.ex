defmodule DataAggregator.Records.ImageUpload.Changes.ResetCountBeforeTransaction do
  @moduledoc """
  Resetss `:unmapped_images_count`, `current_mapping_operations_count`, `max_mapping_operations_count` and `:mapped_images_count` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Helpers

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &reset_count/1)
  end

  defp reset_count(%Changeset{data: image_upload} = changeset) do
    # we use a query to count it on the database, to prevent memory bloating
    images_count =
      image_upload
      |> Helpers.compose_mappable_image_query()
      |> Helpers.count_mappable_images()

    case ImageUpload.update(image_upload, %{
           unmapped_images_count: images_count,
           mapped_images_count: 0,
           current_mapping_operations_count: 0,
           max_mapping_operations_count: images_count
         }) do
      {:ok, image_upload} ->
        %{changeset | data: image_upload}

      {:error, reason} ->
        Logger.error("Error while resetting image upload counts: #{inspect(reason)}")
        Changeset.add_error(changeset, reason)
    end
  end
end
