defmodule DataAggregator.Records.Actions.ExportRecords do
  @moduledoc """
  Custom action to export records
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records
  alias DataAggregator.Records.Export

  @impl true
  def run(input, _opts, _context) do
    export = input.arguments.export
    records_query = export.records_query

    mapping = get_mapping(export.mapping)

    path = "#{Path.join([System.tmp_dir!(), "export"])}#{Ecto.UUID.generate()}.csv"

    attachment =
      Records.stream!(records_query)
      |> Stream.map(&map_records(&1, mapping))
      |> export_to_s3(path, mapping)

    with {:ok, export} <- Export.update(export, %{exported_count: Records.count!(records_query)}),
         {:ok, export} <- Export.update_mapping(export, mapping),
         {:ok, export} <- Export.update_attachment(export, attachment) do
      {:ok, export}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp export_to_s3(records, path, mapping) do
    File.open!(path, [:write, :utf8])
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

  defp map_records(records, mapping) do
    Stream.map(records, &map_record(&1, mapping))
  end

  defp map_record(record, mapping) do
    record |> Map.from_struct() |> Map.take(get_headers(mapping))
  end

  defp get_mapping(mapping) do
    case mapping do
      nil -> get_default_mapping()
      _ -> mapping
    end
  end

  defp get_default_mapping do
    Schema.prefixed_attribute_names()
    |> Enum.map(fn name -> {name, Atom.to_string(name)} end)
    |> Enum.into(%{})
  end

  defp get_headers(mapping) do
    get_mapping(mapping) |> Map.values()
  end
end
