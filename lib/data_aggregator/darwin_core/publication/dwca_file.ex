defmodule DataAggregator.DarwinCore.Publication.DwcaFile do
  @moduledoc """
  Behaviour for creating a Darwin Core Archive (DwCA) file.
  """

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.DarwinCore.Schema.Category
  alias DataAggregator.DarwinCore.Schema.DwcAttribute
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  @callback create(query :: Ash.Query.t(), path :: String.t()) ::
              {:ok, file :: any()} | {:error, reason :: any}

  @doc """
  Creates a file with the given extension file type (e.g. :core) and the data from the query at the given path
  """
  @spec create_file!(atom(), Ash.Query.t(), String.t()) :: any()
  def create_file!(extension_type, query, path) do
    header_fields = file_mapping(extension_type)

    headers = get_only_column_headers(header_fields)

    record_attributes = record_attributes(extension_type)

    query
    |> Ash.stream!(page: false)
    |> Stream.map(&map_record(&1, record_attributes))
    |> Stream.map(&FlatFileUtils.map_data_to_headers(&1, header_fields))
    |> FlatFileUtils.store_on_disk!(path, headers)
  end

  @spec get_only_column_headers(list()) :: keyword()
  def get_only_column_headers(header_fields) do
    header_fields
    |> set_id_as_first_column_header({:occ_occurrence_id, "occurrenceID"})
    |> Enum.map(fn {_k, v} -> v end)
  end

  @doc """
  returns a list of all relevant file header fields for the given file type
  """
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

  defp set_id_as_first_column_header(header_fields, {key, column}) do
    headers_without_id = Enum.reject(header_fields, fn {k, _v} -> k == key end)
    [{key, column} | headers_without_id]
  end

  # gives you a map of all relevant record attributes and its values
  @spec map_record(Record.t(), list()) :: map()
  defp map_record(record, record_attributes) do
    raw_layer = get_raw_layer(record, record_attributes)

    encoded_layer = get_encoded_layer(record, record_attributes)

    Map.merge(raw_layer, encoded_layer, fn _key, val1, val2 ->
      case val2 do
        nil -> val1
        _ -> val2
      end
    end)
  end

  # returns a tuple with the name and the dwc_attributes of a given category
  @spec attributes_by_category(Category.t()) :: {String.t(), [DwcAttribute.t()]}
  defp attributes_by_category(category) do
    {category.name, category.dwc_attributes}
  end

  # returns a tuple with the category name and a list of tuples with the
  # attribute name and the corresponding dwc core file column header field
  @spec attributes_prefixed({atom(), list()}) :: {String.t(), list()}
  defp attributes_prefixed({category, attributes}) do
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

  # returns a tuple with the attribute name prefixed with the category name and
  #  the header field of the dwc core file
  @spec prefix(atom(), String.t(), String.t()) :: {atom(), String.t()}
  defp prefix(category, attribute_name, header_field) do
    {String.to_atom("#{category}_#{attribute_name}"), header_field}
  end

  # filter out any non relevant fields for the publication of the given file type
  @spec header_fields({atom(), list()}, atom()) :: {String.t(), list()}
  defp header_fields({category, attributes}, file_type) do
    {category, Enum.filter(attributes, &usable_header_field?(&1, file_type))}
  end

  # returns true if the given header field is relevant for the given file type or
  # is occurrenceID (we use occurrenceID as the ID column in each dwc extension file)
  @spec usable_header_field?(DwcAttribute.t(), atom()) :: boolean()
  defp usable_header_field?(dwca_attribute, file_type) do
    Map.get(dwca_attribute, :dwc_link) != nil and
      (Map.get(dwca_attribute, :dwca_file) == file_type ||
         Map.get(dwca_attribute, :dwc_field) == "occurrenceID")
  end

  # returns a list of all record attributes which are relevant for the given file type
  @spec record_attributes(atom()) :: list()
  defp record_attributes(file_type) do
    Enum.map(file_mapping(file_type), fn {k, _v} -> k end)
  end

  defp get_raw_layer(record, record_attributes) do
    record |> Map.from_struct() |> Map.take(record_attributes)
  end

  defp get_encoded_layer(record, record_attributes) do
    case EncodedRecord.get_by_record(record.id) do
      {:ok, encoded_record} -> encoded_record |> Map.from_struct() |> Map.take(record_attributes)
      {:error, _} -> Map.new()
    end
  end
end
