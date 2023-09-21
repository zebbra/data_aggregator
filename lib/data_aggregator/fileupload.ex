defmodule DataAggregator.FileUpload do
  use Waffle.Definition

  @versions [:original]
  @extension_whitelist ~w(.csv .jpeg .png)

  def acl(:original, _), do: :public_read

  def validate({file, _}) do
    file_extension = file_extension(file)

    case Enum.member?(@extension_whitelist, file_extension) do
      true -> :ok
      false -> {:error, "invalid file type"}
    end
  end

  def file_extension(file) do
    file.file_name |> Path.extname() |> String.downcase()
  end

  @spec storage_dir(atom(), {
          file :: Waffle.Storage.File.t(),
          scope :: Scope.t()
        }) :: String.t()
  def storage_dir(:original, {file, {provider, collection, dataset}}) do
    "providers/#{provider.name}/collections/#{collection.name}/datasets/#{dataset.id}/imports/#{file_extension(file)}/#{:original}"
  end
end

defmodule DataAggregator.FileUpload.Scope do
  alias DataAggregator.Imports.Collection
  alias DataAggregator.Imports.Dataset
  alias DataAggregator.Imports.Provider

  @type provider :: Provider.t()
  @type collection :: Collection.t()
  @type dataset :: Dataset.t()
end
