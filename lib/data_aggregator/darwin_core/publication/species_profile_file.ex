defmodule DataAggregator.DarwinCore.Publication.SpeciesProfileFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the SpeciesProfile Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/species_profile.csv"

    file = DwcaFile.create_file!(:species_profile, query, path)

    {:ok, file}
  end
end
