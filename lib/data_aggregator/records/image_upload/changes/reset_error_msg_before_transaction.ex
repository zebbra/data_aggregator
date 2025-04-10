defmodule DataAggregator.Records.ImageUpload.Changes.ResetErrorMsgBeforeTransaction do
  @moduledoc """
  Sets `:error_message` to `nil` before the transaction is started.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &reset_error_message/1)
  end

  defp reset_error_message(%Changeset{data: image_upload} = changeset) do
    case ImageUpload.set_error_message(image_upload, nil) do
      {:ok, image_upload} ->
        %{changeset | data: image_upload}

      {:error, reason} ->
        Changeset.add_error(changeset, reason)
    end
  end
end
