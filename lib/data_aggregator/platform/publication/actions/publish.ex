defmodule DataAggregator.Platform.Publication.Actions.PublishRecords do
  @moduledoc """
  Custom action to publish records according to a set of rules for a consumer
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Files.Attachment

  @impl true
  def run(input, _opts, _context) do
    export = DataAggregator.Platform.load!(input.arguments.export, [:records])

    path = "#{:code.priv_dir(:data_aggregator)}/export/#{Ecto.UUID.generate()}.csv"

    export.records

    path |> export_to_s3(export.records)
  end

  defp export_to_s3(path, records) do
    File.open!(path, [:write, :utf8])
    |> store_local_file(records)
    |> File.close()

    Attachment.import_from_path(path)
  end

  defp store_local_file(file, records) do
    records
    |> Stream.map(&map_record(&1))
    |> CSV.encode(headers: get_headers())
    |> Stream.each(&IO.write(file, &1))
    |> Stream.run()

    file
  end

  defp map_record(record) do
    record |> Map.from_struct() |> Map.take(get_headers())
  end

  defp get_headers do
    DataAggregator.DarwinCore.Schema.prefixed_attribute_names()
  end
end
