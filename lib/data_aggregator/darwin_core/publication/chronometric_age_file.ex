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
    header_fields = DwcaFile.file_mapping(:core)
    headers = DwcaFile.get_only_column_headers(header_fields)
    record_attributes = DwcaFile.record_attributes(:core)

    file = FlatFileUtils.open_file!(path)

    %DwcaFile{
      file_descriptor: file,
      header_fields: header_fields,
      headers: headers,
      record_attributes: record_attributes
    }
  end
end
