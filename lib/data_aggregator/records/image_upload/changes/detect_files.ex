defmodule DataAggregator.Records.ImageUpload.Changes.DetectFiles do
  @moduledoc """
  Ash change to count files from a zip file using `:zip` module.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)

    with {:read, {:ok, file}} <- {:read, File.read(path)},
         {:ok, file_names_with_comment} <- :zip.list_dir(file) do
      count =
        Enum.count(file_names_with_comment, fn entry ->
          case entry do
            {:zip_comment, _} -> false
            _ -> true
          end
        end)

      Changeset.change_attribute(changeset, :images_count, count)
    else
      {:read, {:error, error}} ->
        Changeset.add_error(changeset, "Could not read file: #{error}")

      {:error, error} ->
        Changeset.add_error(changeset, "Error listing files: #{error}")
    end
  end
end
