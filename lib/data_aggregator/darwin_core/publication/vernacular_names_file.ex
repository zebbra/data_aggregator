defmodule DataAggregator.DarwinCore.Publication.VernacularNamesFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the VernacularNames Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = "#{path}/vernacular_names.csv"

    # TODO: this is an extension file coming from json data, so it should be created differently
    DwcaFile.create_file!(:vernacular_names, stream, path)
  end
end
