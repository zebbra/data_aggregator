defmodule DataAggregator.DarwinCore.Publication.MaterialSampleFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the MaterialSample Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = path <> "/material_sample.csv"

    DwcaFile.create_file!(:material_sample, stream, path)

    stream
  end
end
