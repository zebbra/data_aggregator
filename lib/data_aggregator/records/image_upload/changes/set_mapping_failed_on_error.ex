defmodule DataAggregator.Records.ImageUpload.Changes.SetMappingFailedOnError do
  @moduledoc """
  Sets the state to `:mapping_failed` if the transaction fails.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &handle_error/2)
  end

  defp handle_error(_changeset, {:ok, image_upload}) do
    {:ok, image_upload}
  end

  defp handle_error(%Changeset{data: image_upload}, {:error, error}) do
    Logger.warning("Image mapping error: #{inspect(error)}")
    ImageUpload.set_mapping_failed(image_upload)
  end
end
