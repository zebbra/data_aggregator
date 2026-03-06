defmodule DataAggregator.Records.Collection.Actions.ExportRecords do
  @moduledoc """
  Custom action to export records
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Counter
  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant} = _ctx) do
    export = Ash.load!(input.arguments.export, [:collection])

    query =
      Record
      |> AshPagify.query_for_filters_map(export.records_query)
      |> Ash.Query.set_tenant(tenant)

    data_layer = export.data_layer
    header_source = export.header_source

    mapping =
      export.mapping
      |> get_mapping(
        export.collection.import_mapping,
        header_source
      )
      |> ensure_validation_annotation(data_layer, header_source)

    header_labels = get_header_labels(mapping)
    headers = Enum.map(header_labels, fn {_, v} -> v end)

    {:ok, counter} = Counter.start(&Export.add_export_progress(export, &1))

    load =
      case data_layer do
        :encoded -> [:encoded_record]
        :validated -> [:validated_record]
        _ -> []
      end

    attachment =
      query
      |> Ash.stream!(stream_with: :keyset, batch_size: 1000, load: load)
      |> Task.async_stream(
        &transform_record(&1, mapping, data_layer, export.collection, header_labels),
        timeout: to_timeout(second: 30)
      )
      |> Stream.map(fn {:ok, record} -> record end)
      |> Stream.reject(&is_nil/1)
      |> Counter.count_each(counter)
      |> create_file!(headers)
      |> FlatFileUtils.create_zip!()
      |> FlatFileUtils.store_on_s3!(export.collection)

    Counter.stop(counter)

    with {:ok, export} <- Export.update_mapping(export, mapping) do
      Export.update_attachment(export, attachment)
    end
  end

  # create a file from the given records.
  @spec create_file!(any(), [String.t()]) :: any()
  defp create_file!(records, headers) do
    directory = FlatFileUtils.create_directory!("export")
    file_path = "#{directory}/#{Uniq.UUID.uuid7(:slug)}.csv"

    FlatFileUtils.store_on_disk!(records, file_path, headers)

    directory
  end

  # transform a record for export based on the data layer
  @spec transform_record(Record.t(), map(), atom(), any(), list()) :: map()
  defp transform_record(record, mapping, :validated, _collection, header_labels) do
    case record.validated_record do
      nil ->
        Logger.info("Record with id #{record.id} has no validated record, don't return data")
        nil

      _ ->
        record
        |> map_record(mapping, :validated)
        |> FlatFileUtils.map_data_to_headers(header_labels, Schema.dwc_transformers())
    end
  end

  defp transform_record(record, mapping, data_layer, collection, header_labels) do
    record
    |> map_record(mapping, data_layer)
    |> DwcaFile.use_data_from_collection(collection)
    |> FlatFileUtils.map_data_to_headers(header_labels, Schema.dwc_transformers())
  end

  # map the record to the given mapping
  @spec map_record(Record.t(), map(), atom()) :: map()

  defp map_record(record, mapping, :raw) do
    record |> Map.from_struct() |> Map.take(get_data_attributes(mapping))
  end

  defp map_record(record, mapping, :encoded) when record.encoded_record == nil do
    Logger.info(
      "Record with id #{record.id} has no encoded record. Raw Data will be used. Encode the record first to have encoded Data to publish"
    )

    record |> Map.from_struct() |> Map.take(get_data_attributes(mapping))
  end

  defp map_record(record, mapping, :encoded) do
    raw_layer = record |> Map.from_struct() |> Map.take(get_data_attributes(mapping))

    encoded_layer =
      record.encoded_record |> Map.from_struct() |> Map.take(get_data_attributes(mapping))

    Map.merge(raw_layer, encoded_layer)
  end

  defp map_record(record, mapping, :validated) do
    record.validated_record |> Map.from_struct() |> Map.take(get_data_attributes(mapping))
  end

  defp ensure_validation_annotation(mapping, :raw, :dwc_attributes) do
    label =
      mapping["validation_annotation"] || mapping[:validation_annotation] ||
        "validation_annotation"

    mapping
    |> Map.delete("validation_annotation")
    |> Map.put(:validation_annotation, label)
  end

  defp ensure_validation_annotation(mapping, _, _), do: mapping

  # returns the mapping according to the given header source and if a collection- or export-mapping is given.
  @spec get_mapping(map(), list(), atom()) :: map()
  defp get_mapping(export_mapping, collection_mapping, header_source)

  defp get_mapping(export_mapping, _collection_mapping, :custom_selection) when export_mapping != nil, do: export_mapping

  defp get_mapping(_export_mapping, collection_mapping, :collection_mapping) when collection_mapping != nil,
    do: convert_mapping_format(collection_mapping)

  defp get_mapping(_export_mapping, _collection_mapping, :dwc_attributes), do: dwc_attribute_mapping()

  defp get_mapping(_export_mapping, _collection_mapping, _header_source), do: get_default_mapping()

  @spec convert_mapping_format(list()) :: map()
  defp convert_mapping_format(collection_mapping) do
    collection_mapping
    |> Enum.filter(fn entry -> entry["mapped_to"] !== nil end)
    |> Map.new(fn entry ->
      {String.to_atom(entry["mapped_to"]), entry["name"]}
    end)
  end

  defp dwc_attribute_mapping do
    collection_attribute_names_and_fields =
      Enum.map(Schema.collection_attributes(), &{&1.name, &1.dwc_field})

    Map.new(Schema.prefixed_attribute_names_and_dwc_fields() ++ collection_attribute_names_and_fields)
  end

  defp get_default_mapping do
    Map.new(Schema.prefixed_attribute_names(), fn name -> {name, name} end)
  end

  defp get_data_attributes(mapping) do
    Map.keys(mapping) ++ [:extra_data]
  end

  defp get_header_labels(mapping) do
    Map.to_list(mapping)
  end
end
