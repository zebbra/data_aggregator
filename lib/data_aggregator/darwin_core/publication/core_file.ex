defmodule DataAggregator.DarwinCore.Publication.CoreFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) core file implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = path <> "/core.csv"

    DwcaFile.create_file!(:core, query, path)

    {:ok, path}
  end
end
