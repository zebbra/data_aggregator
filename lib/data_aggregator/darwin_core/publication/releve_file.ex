defmodule DataAggregator.DarwinCore.Publication.ReleveFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) file for the Releve Extension
   implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Misc.FlatFileUtils

  def open_file!(path) do
    path = "#{path}/releve.csv"
    header_fields = DwcaFile.file_mapping(:releve)
    headers = DwcaFile.get_only_column_headers(header_fields)
    record_attributes = DwcaFile.record_attributes(:releve)

    file = FlatFileUtils.open_file!(path)

    %DwcaFile{
      file_descriptor: file,
      header_fields: DwcaFile.reverse_header_fields(headers, header_fields),
      headers: headers,
      record_attributes: record_attributes,
      file_type: :releve
    }
  end
end
