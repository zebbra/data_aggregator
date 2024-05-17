defmodule DataAggregator.Gbif.RestAPIStub do
  @moduledoc """
  Module to interact with the GBIF Rest API in tests. Subs the real RestAPI module, so no api requests will be made.

  Note while stubbing:

      note for anyone facing the issue of having his/her stub/expect not called:
      make sure that the function you are stubbing/expecting is called NOT within the
      same module the function is declared!

      clean design helps: move stubable functions and api clients to a separate modules

      https://github.com/edgurgel/mimic/issues/27

  """

  def register_dataset(_collection_name) do
    {:ok, %{status: 201, body: "1234-1234-1234-1234"}}
  end

  def create_endpoint(_file_url, _registration) do
    {:ok, %{status: 201, body: "1234"}}
  end

  def search_for_occurrences(catalog_number, dataset_key) do
    {:ok,
     %{
       status: 200,
       body: %{
         "offset" => 0,
         "limit" => 20,
         "endOfRecords" => true,
         "count" => 1,
         "results" => [
           %{
             "key" => 2_283_918_090,
             "datasetKey" => dataset_key,
             "publishingOrgKey" => "1354d651-e529-4a8e-95be-faa807639461",
             "installationKey" => "dc9d8bd0-3c20-4fba-b7ff-26d654817ea7",
             "hostingOrganizationKey" => "23e067c0-a255-11da-beae-b8a03c50a862",
             "publishingCountry" => "CH",
             "protocol" => "EML",
             "lastCrawled" => "2023-01-08T02:10:37.928+00:00",
             "lastParsed" => "2024-01-24T20:52:36.178+00:00",
             "crawlId" => 208,
             "extensions" => {},
             "basisOfRecord" => "PRESERVED_SPECIMEN",
             "occurrenceStatus" => "PRESENT",
             "lifeStage" => "Adult",
             "taxonKey" => 4_450_058,
             "kingdomKey" => 1,
             "phylumKey" => 54,
             "classKey" => 216,
             "orderKey" => 1470,
             "familyKey" => 4_449_504,
             "genusKey" => 4_406_598,
             "speciesKey" => 4_450_058,
             "acceptedTaxonKey" => 4_450_058,
             "scientificName" => "Aplocnemus impressus (Marsham, 1802)",
             "acceptedScientificName" => "Aplocnemus impressus (Marsham, 1802)",
             "kingdom" => "Animalia",
             "phylum" => "Arthropoda",
             "order" => "Coleoptera",
             "family" => "Dasytidae",
             "genus" => "Aplocnemus",
             "species" => "Aplocnemus impressus",
             "genericName" => "Aplocnemus",
             "specificEpithet" => "impressus",
             "taxonRank" => "SPECIES",
             "taxonomicStatus" => "ACCEPTED",
             "iucnRedListCategory" => "NE",
             "decimalLatitude" => 46.74473,
             "decimalLongitude" => 6.48989,
             "coordinateUncertaintyInMeters" => 3535.0,
             "elevation" => 600.0,
             "continent" => "EUROPE",
             "stateProvince" => "Vd",
             "year" => 2017,
             "month" => 3,
             "day" => 23,
             "eventDate" => "2017-03-23",
             "startDayOfYear" => 82,
             "endDayOfYear" => 82,
             "institutionKey" => "3e879cad-48a9-428f-848d-1c0d1a6ba94b",
             "isInCluster" => false,
             "datasetID" => "INVERT",
             "datasetName" => "Invertebrate collections",
             "recordedBy" => "Braulin Gaspard",
             "identifiedBy" => "Chittaro Yannick",
             "samplingProtocol" => "Interception trap",
             "geodeticDatum" => "WGS84",
             "class" => "Insecta",
             "countryCode" => "CH",
             "recordedByIDs" => [],
             "identifiedByIDs" => [],
             "gbifRegion" => "EUROPE",
             "country" => "Switzerland",
             "identifier" => catalog_number,
             "catalogNumber" => catalog_number,
             "organismID" => "GBIFCH00642967",
             "institutionCode" => "MZL",
             "ownerInstitutionCode" => "MZL",
             "materialSampleID" => "GBIFCH00642967",
             "gbifID" => "2283918090",
             "occurrenceID" => catalog_number
           }
         ]
       }
     }}
  end

  @spec get_grscicoll_entity(String.t(), atom()) :: {:ok, any()} | {:error, any()}
  def get_grscicoll_entity(key, _kind) do
    {:ok,
     %{
       "institutionKey" => "5b487a79-76ef-4615-93d9-f4ea25a40c33",
       "institutionName" => "Universität Zürich",
       "key" => key
     }}
  end

  @spec get_grscicoll_attributes(String.t(), list()) :: {:ok, map()} | {:error, any()}
  def get_grscicoll_attributes(_reference, _attributes) do
    {:ok, %{"code" => "Z", "name" => "Herbarium - Universität Zürich"}}
  end

  @spec get_collection_options() :: list()
  def get_collection_options do
    ["Z - Herbarium -Universität Zürich", "XYZ"]
  end

  def get_species(species_key) do
    {:ok,
     %{
       status: 200,
       body: %{
         "key" => species_key,
         "nubKey" => 2_492_483,
         "nameKey" => 7_724_841,
         "taxonID" => "gbif:2492483",
         "sourceTaxonKey" => 172_764_999,
         "kingdom" => "Animalia",
         "phylum" => "Chordata",
         "order" => "Passeriformes",
         "family" => "Muscicapidae",
         "genus" => "Oenanthe",
         "kingdomKey" => 1,
         "phylumKey" => 44,
         "classKey" => 212,
         "orderKey" => 729,
         "familyKey" => 9322,
         "genusKey" => 2_492_483,
         "datasetKey" => "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c",
         "constituentKey" => "7ddf754f-d193-4cc9-b351-99906754a03b",
         "parentKey" => 9322,
         "parent" => "Muscicapidae",
         "scientificName" => "Oenanthe Vieillot, 1816",
         "canonicalName" => "Oenanthe",
         "vernacularName" => "wheatear",
         "authorship" => "Vieillot, 1816",
         "nameType" => "SCIENTIFIC",
         "rank" => "GENUS",
         "origin" => "SOURCE",
         "taxonomicStatus" => "ACCEPTED",
         "nomenclaturalStatus" => [],
         "remarks" => "",
         "publishedIn" =>
           "Vieillot, Louis P. 1816. Analyse d'une nouvelle ornithologie élémentaire. Deterville, Paris.: 1-70.",
         "numDescendants" => 111,
         "lastCrawled" => "2023-08-22T23:20:59.545+00:00",
         "lastInterpreted" => "2023-08-22T22:19:29.194+00:00",
         "issues" => [],
         "class" => "Aves"
       }
     }}
  end

  def get_matching_species(_params) do
    {:ok,
     %{
       status: 200,
       body: %{
         "usageKey" => 2_435_194,
         "scientificName" => "Oenanthe Vieillot, 1816",
         "canonicalName" => "Panthera",
         "rank" => "GENUS",
         "status" => "ACCEPTED",
         "confidence" => 100,
         "matchType" => "HIGHERRANK",
         "kingdom" => "Animalia",
         "phylum" => "Chordata",
         "order" => "Passeriformes",
         "family" => "Muscicapidae",
         "genus" => "Oenanthe",
         "kingdomKey" => 1,
         "phylumKey" => 44,
         "classKey" => 359,
         "orderKey" => 732,
         "familyKey" => 9703,
         "genusKey" => 2_435_194,
         "synonym" => false,
         "class" => "Aves"
       }
     }}
  end
end
