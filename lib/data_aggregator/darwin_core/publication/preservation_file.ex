defmodule DataAggregator.DarwinCore.Publication.PreservationFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Preservation Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Records.Collection

  @spec create(Ash.Query.t(), String.t(), Collection.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path, tenant) do
    path = path <> "/preservation.csv"

    file = DwcaFile.create_file!(:preservation, query, path, tenant)

    {:ok, file}
  end
end
