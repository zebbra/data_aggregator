defmodule DataAggregator.DarwinCore.Publication.DistributionFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Distribution Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/distribution.csv"

    file = DwcaFile.create_file!(:distribution, query, path)

    {:ok, file}
  end
end
