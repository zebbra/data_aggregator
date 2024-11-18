defmodule DataAggregator.DarwinCore.Publication.ResourceRelationshipFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the ResourceRelationship Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile

  @spec create(Enumerable.t(), String.t()) :: Enumerable.t()
  def create(stream, path) do
    path = "#{path}/resource_relationship.csv"

    # TODO: this is an extension file coming from json data, so it should be created differently
    DwcaFile.create_file!(:resource_relationship, stream, path)

    stream
  end
end
