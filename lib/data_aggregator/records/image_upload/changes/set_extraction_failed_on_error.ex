defmodule DataAggregator.Records.ImageUpload.Changes.SetExtractionFailedOnError do
  @moduledoc """
  Sets the state to `:failed` if the transaction fails.
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
    Logger.warning("Image extraction error: #{inspect(error)}")
    ImageUpload.set_extraction_failed(image_upload)
  end
end
