defmodule DataAggregator.DarwinCore.Publication.CoreFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) core file implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = path <> "/core.csv"

    DwcaFile.create_file!(:core, stream, path)

    stream
  end
end
