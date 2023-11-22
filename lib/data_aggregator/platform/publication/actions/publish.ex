defmodule DataAggregator.Platform.Publication.Actions.PublishRecords do
  @moduledoc """
  Custom action to publish records according to a set of rules for a consumer
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Files.Attachment

  @impl true
  def run(input, _opts, _context) do
    export = DataAggregator.Platform.load!(input.arguments.export, [:records])

    mapping = get_mapping(export.mapping)
    mapped_records = export.records |> map_records(mapping)

    "#{:code.priv_dir(:data_aggregator)}/export/#{Ecto.UUID.generate()}.csv"
    |> export_to_s3(mapped_records, mapping)
  end

  defp export_to_s3(path, records, mapping) do
    File.open!(path, [:write, :utf8])
    |> store_local_file(records, mapping)
    |> File.close()

    Attachment.import_from_path(path)
  end

  defp store_local_file(file, records, mapping) do
    records
    |> CSV.encode(headers: get_headers(mapping))
    |> Stream.each(&IO.write(file, &1))
    |> Stream.run()

    file
  end

  defp map_records(records, mapping) do
    records |> Stream.map(&map_record(&1, mapping))
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
