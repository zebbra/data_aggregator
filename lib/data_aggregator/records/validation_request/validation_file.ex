defmodule DataAggregator.Records.Validation.ValidationFile do
  @moduledoc """
  Module to create a Validation File to be sent to the InfoSpecies Centers for verification.
  """

  alias __MODULE__
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils

  defstruct [
    :path,
    :headers,
    :record_attributes,
    :collection_attributes,
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
    headers = @collection_headers ++ @record_headers

    {record_attributes, collection_attributes} = attributes_from_schema!()

    %ValidationFile{
      path: path,
      headers: headers,
      record_attributes: record_attributes,
      collection_attributes: collection_attributes,
      file: file
    }
  end

  defp attributes_from_schema! do
    %{
      record: record_attributes_and_headers,
      collection: collection_attributes_and_headers
    } = Schema.prefixed_attribute_names_and_dwc_fields_and_collection_fields()

    record_attributes = attributes!(record_attributes_and_headers, @record_headers)
    collection_attributes = attributes!(collection_attributes_and_headers, @collection_headers)

    {record_attributes, collection_attributes}
  end

  defp attributes!(attributes_and_headers, headers) do
    Enum.map(headers, fn header ->
      case must_find_one!(attributes_and_headers, header) do
        {field, _} -> field
        _ -> raise "Invalid header: #{header}"
      end
    end)
  end

  defp must_find_one!(attributes_and_headers, header) do
    count = Enum.count(attributes_and_headers, &find_header(&1, header))

    case count do
      1 -> Enum.find(attributes_and_headers, &find_header(&1, header))
      0 -> raise "Missing header: #{header}"
      _ -> raise "Duplicate header: #{header}"
    end
  end

  defp find_header({_attribute, dwc_header}, header), do: dwc_header == header
end
