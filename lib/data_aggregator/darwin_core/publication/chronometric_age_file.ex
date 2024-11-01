defmodule DataAggregator.DarwinCore.Publication.ChronometricAgeFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the ChronometricAge Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Records.Collection

  @spec create(Ash.Query.t(), String.t(), Collection.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path, tenant) do
    path = "#{path}/chronometric_age.csv"

    # TODO: this is an extension file coming from json data, so it should be created differently
    file = DwcaFile.create_file!(:chronometric_age, query, path, tenant)

    {:ok, file}
  end
end
