defmodule DataAggregator.Records.ImageUpload.Changes.DetectFiles do
  @moduledoc """
  Ash change to count files from a zip file using `:zip` module.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)

    {:ok, zip_handle} = path |> File.read!() |> :zip.zip_open([:memory])

    {:ok, file_names} = :zip.zip_get(zip_handle)

    Changeset.change_attribute(changeset, :images_count, Enum.count(file_names))
  end
end
