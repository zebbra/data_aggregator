defmodule DataAggregator.Files.Attachment.Changes.StoreFile do
  @moduledoc """
  This change adds a `after_action` hook to import a file from a `path` argument and store it using `DataAggregator.Files.Store`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Store

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> validate_path()
    |> change_filename()
    |> Changeset.before_action(&store_file/1, append: true)
    |> Changeset.load([:url])
  end

  defp validate_path(changeset) do
    path = Changeset.get_argument(changeset, :path)

    if valid_path?(path) do
      changeset
    else
      changeset |> Changeset.add_error(field: :path, message: "path is invalid", value: path)
    end
  end

  defp valid_path?(path) when is_binary(path), do: File.exists?(path)
  defp valid_path?(_path), do: false

  defp change_filename(changeset) do
    case Changeset.get_argument(changeset, :path) do
      path when is_binary(path) ->
        Changeset.change_attribute(changeset, :filename, Path.basename(path))

      _ ->
        changeset
    end
  end

  defp store_file(%Changeset{} = changeset) do
    id = Changeset.get_attribute(changeset, :id)
    path = Changeset.get_argument(changeset, :path)

    case Store.store({path, id}) do
      {:ok, filename} ->
        Logger.info("[#{id}] Successfully uploaded file as #{inspect(filename)}")
        changeset |> Changeset.change_attribute(:filename, filename)

      {:error, error} ->
        message = "[#{id}] Unable to upload file: #{inspect(error)}}"
        Logger.error(message)
        changeset |> Changeset.add_error(field: :file, message: message)
    end
  end
end
