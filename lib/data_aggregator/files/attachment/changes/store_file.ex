defmodule DataAggregator.Files.Attachment.Changes.StoreFile do
  @moduledoc """
  This change adds a `after_action` hook to import a file from a `path` argument and store it using `DataAggregator.Files.Store`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changeset
    |> validate_path()
    |> change_filename()
    |> change_byte_size()
    |> Changeset.after_action(&store_file/2, append: true)
    |> Changeset.load([:url])
  end

  defp validate_path(changeset) do
    path = Changeset.get_argument(changeset, :path)

    if valid_path?(path) do
      changeset
    else
      Changeset.add_error(changeset, field: :path, message: "path is invalid", value: path)
    end
  end

  defp valid_path?(path) when is_binary(path), do: File.exists?(path)
  defp valid_path?(_path), do: false

  defp change_filename(changeset) do
    filename = get_attribute_filename(changeset) || get_path_filename(changeset)
    Changeset.change_attribute(changeset, :filename, filename)
  end

  defp get_attribute_filename(changeset) do
    Changeset.get_attribute(changeset, :filename)
  end

  defp get_path_filename(changeset) do
    case Changeset.get_argument(changeset, :path) do
      path when is_binary(path) -> Path.basename(path)
      _ -> nil
    end
  end

  defp change_byte_size(changeset) do
    path = Changeset.get_argument(changeset, :path)

    if is_binary(path) && File.exists?(path) do
      byte_size = File.stat!(path).size
      Changeset.change_attribute(changeset, :byte_size, byte_size)
    else
      changeset
    end
  end

  defp store_file(%Changeset{} = changeset, %Attachment{} = attachment) do
    path = Changeset.get_argument(changeset, :path)
    file = %{path: path, filename: attachment.filename}

    case Store.store({file, attachment}) do
      {:ok, filename} ->
        Logger.info("[#{attachment.id}] Successfully uploaded file as #{inspect(filename)}")
        {:ok, attachment}

      {:error, error} ->
        message = "[#{attachment.id}] Unable to upload file: #{inspect(error)}}"
        Logger.error(message)
        {:ok, error}
    end
  end
end
