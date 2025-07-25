defmodule DataAggregator.DarwinCore.Publication.ChronometricAgeFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the ChronometricAge Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Misc.FlatFileUtils

  def open_file!(path) do
    path = "#{path}/chronometric_age.csv"
    header_fields = DwcaFile.file_mapping(:chronometric_age)
    headers = DwcaFile.get_only_column_headers(header_fields)
    record_attributes = DwcaFile.record_attributes(:chronometric_age)

    file = FlatFileUtils.open_file!(path)

    %DwcaFile{
      file_descriptor: file,
      header_fields: DwcaFile.reverse_header_fields(headers, header_fields),
      headers: headers,
      record_attributes: record_attributes,
      file_type: :chronometric_age
    }
  end
end
