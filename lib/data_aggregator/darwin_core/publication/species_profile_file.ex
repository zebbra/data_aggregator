defmodule DataAggregator.DarwinCore.Publication.SpeciesProfileFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the SpeciesProfile Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Misc.FlatFileUtils

  def open_file!(path) do
    path = "#{path}/species_profile.csv"
    header_fields = DwcaFile.file_mapping(:species_profile)
    headers = DwcaFile.get_only_column_headers(header_fields)
    record_attributes = DwcaFile.record_attributes(:species_profile)

    file = FlatFileUtils.open_file!(path)

    %DwcaFile{
      file_descriptor: file,
      header_fields: DwcaFile.reverse_header_fields(headers, header_fields),
      headers: headers,
      record_attributes: record_attributes,
      file_type: :species_profile
    }
  end
end
