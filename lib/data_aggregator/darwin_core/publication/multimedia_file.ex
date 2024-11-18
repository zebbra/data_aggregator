defmodule DataAggregator.DarwinCore.Publication.MultimediaFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Multimedia Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = "#{path}/multimedia.csv"

    DwcaFile.create_file!(:multimedia, stream, path)

    stream
  end
end
