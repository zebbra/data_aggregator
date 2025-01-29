defmodule DataAggregator.Records.ImageUpload.Changes.CreateUploadLogAfterAction do
  @moduledoc """
  Creates an image upload log after the image upload is created and the extraction and
  mapping of images went through.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Utils.ImageUploadLogUtils

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &create_image_upload_log/2)
  end

  defp create_image_upload_log(_changeset, image_upload) do
    Logger.debug("Creating the image upload log ...")

    {:ok, image_upload, path} = ImageUploadLogUtils.generate_log_content(image_upload)

    ImageUploadLogUtils.clean_up_temp_files!(path)

    {:ok, image_upload}
  end
end
