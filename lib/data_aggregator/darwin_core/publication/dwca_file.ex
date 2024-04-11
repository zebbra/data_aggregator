defmodule DataAggregator.DarwinCore.Publication.DwcaFile do
  @moduledoc """
  Behaviour for creating a Darwin Core Archive (DwCA) file.
  """

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  @callback create(query :: Ash.Query.t(), path :: String.t()) ::
              {:ok, file :: any()} | {:error, reason :: term}

  @spec create_directory!(String.t()) :: String.t()
  def create_directory!(directory) do
    path = Path.join([System.tmp_dir!(), directory, Ecto.UUID.generate()])

    File.mkdir_p!(path)

    path
  end

  def attributes_by_category(category) do
    {category.name, category.dwc_attributes}
  end

  # returns a tuple with the category name and a list of tuples with the
  # attribute name and the corresponding dwc core file column header field
  @spec attributes_prefixed({String.t(), list()}) :: {String.t(), list()}
  def attributes_prefixed({category, attributes}) do
    {category,
     Enum.map(
       attributes,
       &prefix(
         category,
         &1.attribute.name,
         Map.get(&1, :dwc_field)
       )
     )}
  end

  # gives you a map of all relevant record attributes and its values
  @spec map_record(Record.t(), list()) :: map()
  def map_record(record, record_attributes) do
    raw_layer = get_raw_layer(record, record_attributes)

    encoded_layer = get_encoded_layer(record, record_attributes)

    update_map_with_non_nil_values(raw_layer, encoded_layer)
  end

  defp get_raw_layer(record, record_attributes) do
    record |> Map.from_struct() |> Map.take(record_attributes)
  end

  defp get_encoded_layer(record, record_attributes) do
    case EncodedRecord.get_by_record(record) do
      {:ok, encoded_record} -> encoded_record |> Map.from_struct() |> Map.take(record_attributes)
      {:error, _} -> Map.new()
    end
  end

  # gives you a map of all relevant dwc header fields and the record values
  # in the structure of `%{"verbatimLocality" => nil, "kingdom" => "My Kingdom", ..}`
  @spec map_data_to_headers(map(), list()) :: map()
  def map_data_to_headers(record_data, header_fields) do
    Map.new(header_fields, fn {k, v} -> {v, Map.get(record_data, k)} end)
  end

  @spec create_file!(atom(), Ash.Query.t(), String.t()) :: any()
  def create_file!(extension, query, path) do
    header_fields = file_mapping(extension)
    record_attributes = record_attributes(extension)

    query
    |> Records.stream!()
    |> Stream.map(&map_record(&1, record_attributes))
    |> Stream.map(&map_data_to_headers(&1, header_fields))
    |> store_on_disk!(path)
  end

  def store_on_disk!(records_data, path) do
    file =
      path
      |> File.open!([:write, :utf8])
      |> store_local_file(records_data)

    File.close(file)

    file
  end

  # returns a list of all record attributes which are relevant for the given file type
  @spec record_attributes(atom()) :: list()
  def record_attributes(file_type) do
    Enum.map(file_mapping(file_type), fn {k, _v} -> k end)
  end

  # returns a list of all relevant file header fields for the given file type
  @spec file_header_fields(atom()) :: list()
  def file_header_fields(file_type) do
    Enum.map(file_mapping(file_type), fn {_k, v} -> v end)
  end

  # returns a list of record attributes and it's header field companion in the
  # structure `[eve_event_id: "eventID", eve_parent_event_id: "parentEventID", ...]` for the given file type
  @spec file_mapping(atom()) :: list()
  def file_mapping(file_type) do
    Schema.categories()
    |> Enum.map(&attributes_by_category/1)
    |> Enum.map(&header_fields(&1, file_type))
    |> Enum.map(&attributes_prefixed/1)
    |> Enum.flat_map(fn {_category, attributes} -> attributes end)
  end

  @spec create_zip!(String.t()) :: String.t()
  def create_zip!(directory) do
    zip_path = ~c"#{directory}/#{Ecto.UUID.generate()}.zip"
    files = get_files(directory)
    directory_path = ~c"#{directory}/"

    case :zip.create(zip_path, files, [{:cwd, directory_path}]) do
      {:ok, _} ->
        to_string(zip_path)

      {:error, reason} ->
        raise "Error creating zip file: #{inspect(reason)}"
    end
  end

  @spec get_files(String.t()) :: list(charlist())
  def get_files(path) do
    path
    |> File.ls!()
    |> Enum.map(&String.to_charlist/1)
  end

  # returns a tuple with the attribute name prefixed with the category name and
  #  the header field of the dwc core file
  @spec prefix(String.t(), String.t(), String.t()) :: {atom(), String.t()}
  defp prefix(category, attribute_name, header_field) do
    {String.to_atom("#{category}_#{attribute_name}"), header_field}
  end

  # filter out any non relevant fields for the publication of the given file type
  @spec header_fields({String.t(), list()}, atom()) :: {String.t(), list()}
  defp header_fields({category, attributes}, file_type) do
    {category, Enum.filter(attributes, &(Map.get(&1, :dwca_file) == file_type))}
  end

  defp store_local_file(file, records_data) do
    records_data
    |> CSV.encode(separator: ?,, headers: true)
    |> Stream.each(&IO.write(file, &1))
    |> Stream.run()

    file
  end

  def update_map_with_non_nil_values(map1, map2) do
    Enum.reduce(map2, map1, fn {key, value}, acc_map ->
      # If value in map2 is not nil, update the corresponding value in acc_map (map1)
      case value do
        nil ->
          # If value is nil, do not update acc_map
          acc_map

        _ ->
          # Update acc_map with non-nil value
          %{acc_map | key => value}
      end
    end)
  end
end
