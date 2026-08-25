defmodule DataAggregator.Records.Validation.ValidationFile do
  @moduledoc """
  Module to create a Validation File to be sent to the InfoSpecies Centers for verification.
  """

  alias __MODULE__
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils

  @type t() :: %__MODULE__{}

  defstruct [
    :path,
    :collection_attributes_and_headers,
    :record_attributes_and_headers,
    :encoded_attributes_and_headers,
    :attribute_names,
    :file
  ]

  @collection_headers [
    "collectionID",
    "collectionCode",
    "datasetID",
    "institutionCode",
    "gbifDOI"
  ]

  @record_headers [
    "barcodeLabel",
    "basisOfRecord",
    "catalogNumber",
    "datasetName",
    "dateIdentified",
    "fieldNotes",
    "fieldNumber",
    "gbifCHID",
    "occurrenceID",
    "verbatimLabel",
    "anatomicalDescription",
    "associatedMedia",
    "associatedOccurrences",
    "associatedOrganisms",
    "associatedReferences",
    "associatedSequences",
    "associatedTaxa",
    "bibliographicCitation",
    "degreeOfEstablishment",
    "establishmentMeans",
    "evidenceType",
    "habitat",
    "habitatCode",
    "habitatContact",
    "habitatInclusion",
    "habitatRef",
    "identificationQualifier",
    "identificationReferences",
    "identificationRemarks",
    "identificationVerificationStatus",
    "identifiedBy",
    "identifiedByID",
    "individualCount",
    "landscapeStructure",
    "lastVerifiedBy",
    "lifeStage",
    "nameAccordingTo",
    "occurrenceStatus",
    "organismID",
    "organismQuantity",
    "organismQuantityType",
    "partOfOrganism",
    "preparations",
    "previousIdentifications",
    "recordedBy",
    "references",
    "scientificName",
    "scientificNameAuthorship",
    "sex",
    "specifyAuthorOfRecord",
    "substratum",
    "syntaxonName",
    "taxonIdCH",
    "verbatimIdentification",
    "day",
    "endOfPeriodDay",
    "endOfPeriodMonth",
    "endOfPeriodYear",
    "eventDate",
    "month",
    "verbatimEventDate",
    "year",
    "coordinatePrecision",
    "coordinateUncertaintyInMeters",
    "country",
    "countryCode",
    "decimalLatitude",
    "decimalLongitude",
    "georeferencedBy",
    "georeferencedDate",
    "georeferenceProtocol",
    "georeferenceRemarks",
    "georeferenceSources",
    "georeferenceVerificationStatus",
    "locality",
    "locationAccordingTo",
    "locationID",
    "locationRemarks",
    "maximumElevationInMeters",
    "minimumDepthInMeters",
    "minimumElevationInMeters",
    "municipality",
    "placeOfOrigin",
    "pointRadiusSpatialFit",
    "specifyLocality",
    "stateProvince",
    "swissCoordinatesLv03_E",
    "swissCoordinatesLv03_N",
    "swissCoordinatesLv95_E",
    "swissCoordinatesLv95_N",
    "verbatimCoordinates",
    "verbatimCoordinateSystem",
    "verbatimDepth",
    "verbatimElevation",
    "verbatimLatitude",
    "verbatimLocality",
    "verbatimLongitude",
    "waterBody"
  ]

  @doc """
  The Darwin Core fields of a record that are sent to the InfoSpecies Centers for validation.
  """
  @spec record_headers() :: [String.t()]
  def record_headers, do: @record_headers

  @doc """
  Opens a validation file at the given path and returns a ValidationFile struct.
  This describes a wrapper around a csv file with meta information for further record data processing.
  """
  @spec open_file!(String.t()) :: t()
  def open_file!(path) do
    path = "#{path}/validation.csv"
    file = FlatFileUtils.open_file!(path)

    {collection_attrs_and_headers, record_attrs_and_headers, encoded_attrs_and_headers} =
      attributes_and_headers_from_schema!()

    %ValidationFile{
      path: path,
      collection_attributes_and_headers: collection_attrs_and_headers,
      record_attributes_and_headers: record_attrs_and_headers,
      encoded_attributes_and_headers: encoded_attrs_and_headers,
      attribute_names: attribute_names(collection_attrs_and_headers, record_attrs_and_headers),
      file: file
    }
  end

  @spec attributes_and_headers_from_schema!() ::
          {list({String.t(), String.t()}), list({String.t(), String.t()}), list({String.t(), String.t()})}
  defp attributes_and_headers_from_schema! do
    %{
      collection: collection_attributes_and_headers,
      record: record_attributes_and_headers
    } = Schema.prefixed_attribute_names_and_dwc_fields_and_collection_fields()

    collection_attributes_and_headers =
      Enum.filter(collection_attributes_and_headers, fn {_, header} ->
        header in @collection_headers
      end)

    record_attributes_and_headers =
      Enum.filter(record_attributes_and_headers, fn {_, header} ->
        header in @record_headers
      end)

    encoded_attributes_and_headers =
      Enum.map(record_attributes_and_headers, fn {key, value} ->
        {key, "encoded " <> value}
      end)

    {collection_attributes_and_headers, record_attributes_and_headers, encoded_attributes_and_headers}
  end

  # The attributes behind each group, used by the validation request to detect whether
  # a record changed -- independently of the header labels those attributes carry.
  @spec attribute_names(Keyword.t(), Keyword.t()) :: %{String.t() => MapSet.t(String.t())}
  defp attribute_names(collection_attributes_and_headers, record_attributes_and_headers) do
    record_attribute_names = attribute_name_set(record_attributes_and_headers)

    %{
      "collection_data" => attribute_name_set(collection_attributes_and_headers),
      "record_data" => record_attribute_names,
      # mirrors the record group, only the header labels differ
      "encoded_data" => record_attribute_names
    }
  end

  @spec attribute_name_set(Keyword.t()) :: MapSet.t(String.t())
  defp attribute_name_set(attributes_and_headers) do
    attributes_and_headers |> Keyword.keys() |> MapSet.new(&to_string/1)
  end
end
