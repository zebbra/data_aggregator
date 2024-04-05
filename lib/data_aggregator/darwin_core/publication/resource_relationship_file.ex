defmodule DataAggregator.DarwinCore.Publication.ResourceRelationshipFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the ResourceRelationship Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    path = "#{path}/resource_relationship.csv"

    file = DwcaFile.create_file!(:resource_relationship, query, path)

    {:ok, file}
  end
end
