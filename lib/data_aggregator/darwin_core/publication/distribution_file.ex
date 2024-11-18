defmodule DataAggregator.DarwinCore.Publication.DistributionFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Distribution Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = "#{path}/distribution.csv"

    # TODO: this is an extension file coming from json data, so it should be created differently
    DwcaFile.create_file!(:distribution, stream, path)

    stream
  end
end
