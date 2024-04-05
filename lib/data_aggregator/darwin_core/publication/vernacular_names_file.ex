defmodule DataAggregator.DarwinCore.Publication.VernacularNamesFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the VernacularNames Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/vernacular_names.csv"

    file = DwcaFile.create_file!(:vernacular_names, query, path)

    {:ok, file}
  end
end
