defmodule DataAggregator.DarwinCore.Publication.MaterialSampleFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the MaterialSample Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/material_sample.csv"

    file = DwcaFile.create_file!(:material_sample, query, path)

    {:ok, file}
  end
end
