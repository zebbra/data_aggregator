defmodule DataAggregator.DarwinCore.Publication.PreservationFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Preservation Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = path <> "/preservation.csv"

    DwcaFile.create_file!(:preservation, stream, path)

    stream
  end
end
