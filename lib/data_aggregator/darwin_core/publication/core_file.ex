defmodule DataAggregator.DarwinCore.Publication.CoreFile do
  @moduledoc """
  Module to create a Darwin Core Archive (DwCA) core file implementing `DataAggregator.DarwinCore.Publication.DwcaFile` behaviour.
  """

  @behaviour DataAggregator.DarwinCore.Publication.DwcaFile

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Records

  @spec create(Ash.Query.t(), String.t()) :: {:ok, any()} | {:error, any()}
  def create(query, path) do
    core_header_fields = DwcaFile.file_mapping(:core)
    record_attributes = DwcaFile.record_attributes(:core)

    path = "#{path}/core.csv"

    file =
      query
      |> Records.stream!()
      |> Stream.map(&DwcaFile.map_record(&1, record_attributes))
      |> Stream.map(&DwcaFile.map_data_to_headers(&1, core_header_fields))
      |> DwcaFile.store_on_disk!(path)

    {:ok, file}
  end
end
