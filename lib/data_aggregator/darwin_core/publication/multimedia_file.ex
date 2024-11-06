defmodule DataAggregator.DarwinCore.Publication.MultimediaFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Multimedia Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Records.Collection

  @spec create(Ash.Query.t(), String.t(), Collection.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path, tenant) do
    path = "#{path}/multimedia.csv"

    file = DwcaFile.create_file!(:multimedia, query, path, tenant)

    {:ok, file}
  end
end
