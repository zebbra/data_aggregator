defmodule DataAggregator.Records.Validation.ValidationFile do
  @moduledoc """
  Module to create a Validation File to be sent to the InfoSpecies Centers for verification.
  """

  alias __MODULE__
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils

  defstruct [
    :path,
    :collection_attributes_and_headers,
    :record_attributes_and_headers,
    :encoded_attributes_and_headers,
    :file
  ]

  @collection_headers [
    "collectionID",
    "collectionCode",
    "datasetID",
    "institutionCode",
    "institutionID",
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
    "gbifID",
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
    "county",
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

  def open_file!(path) do
    path = "#{path}/validation.csv"
    file = FlatFileUtils.open_file!(path)

    {collection_attrs_and_headers, record_attrs_and_headers, encoded_attrs_and_headers} =
      attributes_and_headers_from_schema!()

    # record_attributes = attributes!(record_attrs_and_headers, @record_headers)
    # collection_attributes = attributes!(collection_attrs_and_headers, @collection_headers)
    # encoded_attributes = attributes!(encoded_attrs_and_headers, @record_headers)

    %ValidationFile{
      path: path,
      collection_attributes_and_headers: collection_attrs_and_headers,
      record_attributes_and_headers: record_attrs_and_headers,
      encoded_attributes_and_headers: encoded_attrs_and_headers,
      file: file
    }
  end

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
end
