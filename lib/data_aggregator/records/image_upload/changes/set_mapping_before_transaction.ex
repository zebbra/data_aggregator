defmodule DataAggregator.Records.ImageUpload.Changes.SetMappingBeforeTransaction do
  @moduledoc """
  Sets the state to `:mapping` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &set_mapping/1)
  end

  defp set_mapping(%Changeset{data: image_upload} = changeset) do
    case ImageUpload.set_mapping(image_upload) do
      {:ok, image_upload} ->
        %{changeset | data: image_upload}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
