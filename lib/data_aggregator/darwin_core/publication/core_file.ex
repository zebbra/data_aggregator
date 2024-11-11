defmodule DataAggregator.DarwinCore.Publication.CoreFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) core file implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Records.Collection

  @spec create(Ash.Query.t(), String.t(), Collection.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path, tenant) do
    path = path <> "/core.csv"

    DwcaFile.create_file!(:core, query, path, tenant)

    {:ok, path}
  end
end
