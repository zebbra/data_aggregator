defmodule DataAggregator.Records.Actions.ExportRecords do
  @moduledoc """
  Custom action to export records
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records
  alias DataAggregator.Records.Export

  require Logger

  @impl true
  def run(input, _opts, _context) do
    export = input.arguments.export
    records_query = export.records_query

    mapping = get_mapping_or_default(export.mapping)

    path = "#{Path.join([System.tmp_dir!(), "export"])}#{Ecto.UUID.generate()}.csv"

    attachment =
      records_query
      |> Records.stream!()
      |> Stream.map(&map_record(&1, mapping, export))
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

  defp map_record(record, mapping, export) do
    Export.add_export_progress(export, 1)

    record |> Map.from_struct() |> Map.take(get_headers(mapping))
  end

  defp get_mapping_or_default(nil), do: get_default_mapping()

  defp get_mapping_or_default(mapping), do: mapping

  defp get_default_mapping do
    Map.new(Schema.prefixed_attribute_names(), fn name -> {name, name} end)
  end

  defp get_headers(mapping) do
    mapping |> get_mapping_or_default() |> Map.values()
  end
end
