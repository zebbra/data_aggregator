defmodule DataAggregator.DarwinCore.Publication.ChronometricAgeFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the ChronometricAge Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/chronometric_age.csv"

    # TODO: this is an extension file coming from json data, so it should be created differently
    file = DwcaFile.create_file!(:chronometric_age, query, path)

    {:ok, file}
  end
end
