defmodule DataAggregator.Records.ImageUpload.Changes.DetectFiles do
  @moduledoc """
  Ash change to count files from a zip file using `:zip` module.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)

    {:ok, file_names_with_comment} = path |> File.read!() |> :zip.list_dir()

    count =
      Enum.count(file_names_with_comment, fn entry ->
        case entry do
          {:zip_comment, _} -> false
          _ -> true
        end
      end)

    Changeset.change_attribute(changeset, :images_count, count)
  end
end
