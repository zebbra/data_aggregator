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

    message =
      cond do
        error == nil ->
          "Error while mapping images. No more information available"

        Map.get(error, :errors) == nil || error.errors == [] ->
          "#{inspect(error)}"

        true ->
          extract_error_message(error)
      end

    with {:ok, image_upload} <- set_error_message(image_upload, message),
         {:ok, image_upload} <- set_mapping_failed(image_upload),
         {:ok, image_upload} <- set_general_mapping_progress_count(image_upload, error) do
      {:ok, image_upload}
    else
      error ->
        Logger.error("Error while setting image upload to mapping_failed: #{inspect(error)}")
        {:error, error}
    end
  end

  defp extract_error_message(error) do
    Enum.map_join(error.errors, ", ", fn error ->
      if error.message == nil do
        "#{inspect(error)}"
      else
        error.message
      end
    end)
  end

  defp set_error_message(image_upload, message) do
    ImageUpload.set_error_message(image_upload, message)
  end

  defp set_mapping_failed(image_upload) do
    ImageUpload.set_mapping_failed(image_upload)
  end

  defp set_general_mapping_progress_count(image_upload, %{data: data}) do
    ImageUpload.update(image_upload, %{
      general_mapping_progress_count: data.general_mapping_progress_count
    })
  end

  defp set_general_mapping_progress_count(image_upload, _error) do
    ImageUpload.update(image_upload, %{
      general_mapping_progress_count: 0
    })
  end
end
