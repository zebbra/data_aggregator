defmodule DataAggregator.DarwinCore.Publication.MultimediaFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Multimedia Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/multimedia.csv"

    file = DwcaFile.create_file!(:multimedia, query, path)

    {:ok, file}
  end
end
