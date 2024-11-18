defmodule DataAggregator.DarwinCore.Publication.ReleveFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Releve Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = path <> "/releve.csv"

    DwcaFile.create_file!(:releve, stream, path)

    stream
  end
end
