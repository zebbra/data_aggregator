defmodule DataAggregator.Records.ImageUpload.Changes.SetExtractingBeforeTransaction do
  @moduledoc """
  Sets the state to `:extracting` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_extracting/1)
  end

  defp set_extracting(%Changeset{data: image_upload} = changeset) do
    case ImageUpload.set_extracting(image_upload) do
      {:ok, image_upload} ->
        %Changeset{changeset | data: image_upload}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
