defmodule DataAggregator.DarwinCore.Publication.ReferencesFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the References Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/references.csv"

    file = DwcaFile.create_file!(:references, query, path)

    {:ok, file}
  end
end
