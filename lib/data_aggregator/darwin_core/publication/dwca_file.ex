defmodule DataAggregator.DarwinCore.Publication.DwcaFile do
  @moduledoc """
  Behaviour for creating a Darwin Core Archive (DwCA) file.
  """

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.DarwinCore.Schema.Category
  alias DataAggregator.DarwinCore.Schema.DwcAttribute
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Logger

  defstruct [:file_descriptor, :header_fields, :headers, :record_attributes, :file_type]
  @type t() :: %__MODULE__{}

  @callback open_file!(String.t()) :: t()
  @transformers Schema.dwc_transformers()

  @doc """
  Writes the given records to a DwCA file on disk. Transforms the data according to the
  given header fields (from the meta) and transformers.
  """
  @spec write_file!(Enumerable.t(), t(), Collection.t()) :: any()
  def write_file!(records, meta, collection) do
    records
    |> Stream.map(&map_record(&1, meta.record_attributes))
    |> Stream.map(&use_data_from_collection(&1, collection))
    |> Stream.map(&FlatFileUtils.map_data_to_headers_list(&1, meta.header_fields, @transformers))
    |> FlatFileUtils.store_on_disk!(meta.file_descriptor)
  end

  def write_headers(%__MODULE__{file_descriptor: file, headers: headers}) do
    FlatFileUtils.store_on_disk!([headers], file)
  end

  @spec get_only_column_headers(list()) :: keyword()
  def get_only_column_headers(header_fields) do
    header_fields
    |> set_id_as_first_column_header({:occ_occurrence_id, "occurrenceID"})
    |> Enum.map(fn {_k, v} -> v end)
  end

  # returns the headers mapped in order to the header_fields keys
  # prepends the :occ_occurrence_id as the first column header
  def reverse_header_fields(headers, header_fields) do
    Enum.map(headers, fn header ->
      if header == "occurrenceID" do
        :occ_occurrence_id
      else
        header_key(header_fields, header)
      end
    end)
  end

  defp header_key(header_fields, header) do
    {k, _v} = Enum.find(header_fields, fn {_k, v} -> v == header end)
    k
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
    schema_attributes =
      Schema.categories()
      |> Enum.map(&attributes_by_category/1)
      |> Enum.map(&header_fields(&1, file_type))
      |> Enum.map(&attributes_prefixed/1)
      |> Enum.flat_map(fn {_category, attributes} -> attributes end)

    collection_attributes =
      Schema.collection_attributes()
      |> Enum.filter(fn attribute ->
        attribute.dwca_file == file_type
      end)
      |> Enum.map(&{&1.name, &1.dwc_field})

    schema_attributes ++ collection_attributes
  end

  defp set_id_as_first_column_header(header_fields, {key, column}) do
    headers_without_id = Enum.reject(header_fields, fn {k, _v} -> k == key end)
    [{key, column} | headers_without_id]
  end

  # gives you a map of all relevant record attributes and its values
  @spec map_record(Record.t(), list()) :: map()
  defp map_record(record, record_attributes) do
    record |> Map.from_struct() |> Map.take(record_attributes)
  end

  @doc """
  Replaces the values of the given record with the values from the collection
  What values to be replaced is defined in collection_attributes map defined in Schema.
  """
  def use_data_from_collection(record, collection) do
    Enum.reduce(Schema.collection_attributes(), record, fn attribute, acc ->
      Map.put(acc, attribute.name, Map.get(collection, attribute.collection_field))
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
  def record_attributes(file_type) do
    Enum.map(file_mapping(file_type), fn {k, _v} -> k end)
  end
end
