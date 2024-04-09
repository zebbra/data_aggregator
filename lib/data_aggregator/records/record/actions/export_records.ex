defmodule DataAggregator.Records.Actions.ExportRecords do
  @moduledoc """
  Custom action to export records
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, _context) do
    export = Records.load!(input.arguments.export, [:collection])

    records_query = export.records_query
    data_layer = export.data_layer
    header_source = export.header_source

    mapping =
      get_mapping(
        export.mapping,
        export.collection.import_mapping,
        header_source
      )

    path = "#{Path.join([System.tmp_dir!(), "export"])}#{Ecto.UUID.generate()}.csv"

    attachment =
      records_query
      |> Records.stream!()
      |> Stream.map(&map_record(&1, mapping, export, data_layer))
      |> export_to_s3!(path, mapping)

    with {:ok, export} <- Export.update_mapping(export, mapping) do
      Export.update_attachment(export, attachment)
    end
  end

  defp export_to_s3!(records, path, mapping) do
    path
    |> File.open!([:write, :utf8])
    |> store_local_file(records, mapping)
    |> File.close()

    Attachment.import_from_path!(path)
  end

  defp store_local_file(file, records, mapping) do
    records
    |> CSV.encode(headers: get_headers(mapping))
    |> Stream.each(&IO.write(file, &1))
    |> Stream.run()

    file
  end

  @spec map_record(Record.t(), map(), Export.t(), atom()) :: map()
  defp map_record(record, mapping, export, :raw) do
    Export.add_export_progress(export, 1)

    record |> Map.from_struct() |> Map.take(get_headers(mapping))
  end

  defp map_record(record, mapping, export, :encoded) do
    Export.add_export_progress(export, 1)

    record = Records.load!(record, [:encoded_record])

    if record.encoded_record == nil do
      Logger.info(
        "Record with id #{record.id} has no encoded record. Raw Data will be used. Encode the record first to have encoded Data to publish"
      )

      record |> Map.from_struct() |> Map.take(get_headers(mapping))
    else
      record.encoded_record |> Map.from_struct() |> Map.take(get_headers(mapping))
    end
  end

  @spec get_mapping(map(), list(), atom()) :: map()
  defp get_mapping(export_mapping, _collection_mapping, :custom_selection) when export_mapping != nil, do: export_mapping

  defp get_mapping(_export_mapping, collection_mapping, :collection_mapping) when collection_mapping != nil,
    do: convert_mapping_format(collection_mapping)

  defp get_mapping(_export_mapping, _collection_mapping, :dwc_attributes), do: dwc_attribute_mapping()

  defp get_mapping(_export_mapping, _collection_mapping, _header_source), do: get_default_mapping()

  defp get_headers(mapping) do
    Map.values(mapping)
  end

  @spec convert_mapping_format(list()) :: map()
  defp convert_mapping_format(collection_mapping) do
    Map.new(collection_mapping, fn entry ->
      {String.to_atom(entry["mapped_to"]), entry["name"]}
    end)
  end

  defp dwc_attribute_mapping do
    Map.new(Schema.prefixed_attribute_names_and_dwc_fields())
  end

  defp get_default_mapping do
    Map.new(Schema.prefixed_attribute_names(), fn name -> {name, name} end)
  end
end
