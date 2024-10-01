defmodule DataAggregator.Records.ImageUpload.Changes.ValidateFile do
  @moduledoc """
  Ash change to validate a zip file using `:zip` module.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)

    with {:read, {:ok, file}} <- {:read, File.read(path)},
         {:ok, _file_names_with_comment} <- :zip.list_dir(file) do
      changeset
    else
      {:read, {:error, error}} ->
        Changeset.add_error(changeset, "Could not read file: #{error}")

      {:error, error} ->
        Changeset.add_error(changeset, "Error listing files: #{error}")
    end
  end
end
