defmodule DataAggregator.Records.ImageUpload.Changes.SetTimeout do
  @moduledoc """
  Sets the timeout for the image upload action.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    timeout = Records.image_upload_timeout()

    Logger.info("Image upload timeout set to #{timeout}ms")
    Changeset.timeout(changeset, timeout)
  end
end
