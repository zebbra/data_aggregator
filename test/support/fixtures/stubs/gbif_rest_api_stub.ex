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
  alias DataAggregator.Types.Api

  @institution_key "5b487a79-76ef-4615-93d9-f4ea25a40c33"
  def institution_key, do: @institution_key

  @other_institution_key "1354d651-e529-4a8e-95be-faa807639461"
  def other_institution_key, do: @other_institution_key

  @grscicoll_reference "322ce107-3156-4420-8a2b-7f17efeaa472"
  def grscicoll_reference, do: @grscicoll_reference

  @other_grscicoll_reference "322ce107-3156-4420-8a2b-7f17efeaa473"
  def other_grscicoll_reference, do: @other_grscicoll_reference

  @missing_institution_data_grscicoll_reference "6267ef74-8393-4d57-a9f8-2b36831f5042"
  def missing_institution_data_grscicoll_reference, do: @missing_institution_data_grscicoll_reference

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

  @spec get_grscicoll_entity(String.t(), atom()) :: Api.response_body()
  def get_grscicoll_entity(key, _kind) do
    {:ok,
     %{
       "institutionKey" => @institution_key,
       "institutionName" => "Universität Zürich",
       "institutionCode" => "Z",
       "key" => key
     }}
  end

  @spec get_one_collection(String.t()) :: Api.response_body()
  def get_one_collection(_reference) do
    {:ok,
     %{
       "institutionKey" => @institution_key,
       "apiUrls" => [],
       "catalogUrls" => [],
       "geographicCoverage" => "Worldwide; especially Central Europe, southern Africa, New Caledonia",
       "comments" => [],
       "institutionName" => "Herbarium of the University of Zürich",
       "address" => %{
         "address" => "Zollikerstrasse 107",
         "city" => "Zürich",
         "country" => "CH",
         "key" => 33_456,
         "postalCode" => "CH-8008"
       },
       "createdBy" => "ih-sync",
       "incorporatedCollections" => ["BERN (2008", "bryophytes)"],
       "taxonomicCoverage" => "Algae, fungi, bryophytes, and vascular plants",
       "machineTags" => [],
       "key" => @grscicoll_reference,
       "masterSource" => "IH",
       "personalCollection" => false,
       "occurrenceCount" => 0,
       "alternativeCodes" => [],
       "created" => "2020-03-31T12:39:13.283+00:00",
       "importantCollectors" => [
         "J. H. Albrecht",
         "O. Appert",
         "M. Baumann-Bodenheim",
         "W. Becker",
         "A. Braun",
         "P. Culmann",
         "A. U. Däniker",
         "K. Dinter",
         "A. Ernst",
         "W. Geilinger",
         "J. Gessner",
         "M. B. F. Gugelberg von Moos",
         "J. Hegetschweiler",
         "T. von Heldreich",
         "T. C. J. Herzog",
         "H. Hürlimann",
         "R. Keller",
         "K. U. Kramer",
         "F. Markgraf",
         "I. Markgraf-Dannenberg",
         "J. Müller",
         "M. Rautanen",
         "A. Rehmann",
         "J. J. Roemer",
         "W. Schibler",
         "H. Schinz",
         "F. R. R. Schlechter",
         "H.-J. E. Schlieben",
         "E. Schmid",
         "E. Sickenberger"
       ],
       "identifiers" => [
         %{
           "created" => "2020-03-31T12:39:13.288+00:00",
           "createdBy" => "ih-sync",
           "identifier" => "gbif:ih:irn:126516",
           "key" => 620_469,
           "type" => "IH_IRN"
         }
       ],
       "mailingAddress" => %{
         "address" => "Zollikerstrasse 107",
         "city" => "Zürich",
         "country" => "CH",
         "key" => 33_457,
         "postalCode" => "CH-8008"
       },
       "displayOnNHCPortal" => true,
       "code" => "Z",
       "tags" => [],
       "modifiedBy" => "ih-sync",
       "phone" => ["[41] 44 634 84 11"],
       "contactPersons" => [
         %{
           "address" => [],
           "city" => "Zürich",
           "country" => "CH",
           "created" => "2021-10-11T13:58:40.433+00:00",
           "createdBy" => "gbif-collections",
           "email" => ["reto.nyffeler@systbot.uzh.ch"],
           "fax" => [],
           "firstName" => "Reto",
           "key" => 20_769,
           "lastName" => "Nyffeler",
           "modified" => "2021-10-11T13:58:40.433+00:00",
           "modifiedBy" => "gbif-collections",
           "notes" => "Research pursuits: Alpine plants; Cactaceae.",
           "phone" => ["[044] 634 84 42"],
           "position" => ["Curator"],
           "primary" => false,
           "taxonomicExpertise" => [],
           "userIds" => [%{"id" => "134592", "type" => "IH_IRN"}]
         },
         %{
           "address" => [],
           "city" => "Zürich",
           "country" => "CH",
           "created" => "2021-10-11T13:58:40.722+00:00",
           "createdBy" => "gbif-collections",
           "email" => ["heike.hofmann@systbot.uzh.ch"],
           "fax" => [],
           "firstName" => "Heike",
           "key" => 20_785,
           "lastName" => "Hofmann",
           "modified" => "2021-10-11T13:58:40.722+00:00",
           "modifiedBy" => "gbif-collections",
           "phone" => [],
           "position" => ["Curator of Bryophytes"],
           "primary" => false,
           "taxonomicExpertise" => [],
           "userIds" => [%{"id" => "240840", "type" => "IH_IRN"}]
         }
       ],
       "department" => "Department of Systematic and Evolutionary Botany",
       "masterSourceMetadata" => %{
         "created" => "2021-12-21T08:29:33.368+00:00",
         "createdBy" => "gbif-collections",
         "key" => 5604,
         "source" => "IH_IRN",
         "sourceId" => "126516"
       },
       "preservationTypes" => [],
       "homepage" => "http://www.herbarien.uzh.ch",
       "modified" => "2022-07-12T08:42:51.517+00:00",
       "notes" =>
         "In 1990, the Herbarium of the Eidgenössische Technische Hochschule Zürich (ZT) and the Herbarium of the Universität Zürich (Z) were combined to work together as United Herbaria Zürich Z+ZT. Requests for material to either Z or ZT will be considered as a request to both institutions. Address given above concerns the plant collections of Z+ZT. The bryophyte collection of BERN is maintained separately.The address for the fungi and lichen collections can be found under the entry for ZT. URL of the herbarium is https://www.herbarien.uzh.ch",
       "occurrenceMappings" => [],
       "email" => [],
       "active" => true,
       "numberSpecimens" => 1_840_000,
       "institutionCode" => "Z",
       "contentTypes" => [],
       "collectionSummary" => %{
         "numAlgae" => 50_000,
         "numAlgaeDatabased" => 0,
         "numAlgaeImaged" => 0,
         "numBryos" => 350_000,
         "numBryosDatabased" => 132_800,
         "numBryosImaged" => 132_800,
         "numFungi" => 20_000,
         "numFungiDatabased" => 0,
         "numFungiImaged" => 0
       },
       "name" => "Herbarium - Herbarium of the University of Zürich",
       "typeSpecimenCount" => 0
     }}
  end

  @spec get_grscicoll_collection_attributes(String.t(), list()) :: Api.response_body()
  def get_grscicoll_collection_attributes(@other_grscicoll_reference, _attributes) do
    {:ok,
     %{
       "code" => "Z",
       "name" => "Herbarium - Universität Zürich",
       "institutionKey" => @other_institution_key,
       "institutionName" => "Universität Zürich",
       "institutionCode" => "Z"
     }}
  end

  def get_grscicoll_collection_attributes(@missing_institution_data_grscicoll_reference, _attributes) do
    {:ok,
     %{
       "code" => "Z",
       "name" => "Herbarium - Universität Zürich",
       "institutionKey" => nil,
       "institutionName" => nil,
       "institutionCode" => nil
     }}
  end

  def get_grscicoll_collection_attributes(_reference, _attributes) do
    {:ok,
     %{
       "code" => "Z",
       "name" => "Herbarium - Universität Zürich",
       "institutionKey" => @institution_key,
       "institutionName" => "Universität Zürich",
       "institutionCode" => "Z"
     }}
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

  def get_iucn_redlist_category(_) do
    {:ok,
     %Req.Response{
       status: 200,
       headers: %{
         "accept-ranges" => ["bytes"],
         "age" => ["0"],
         "cache-control" => ["public, max-age=3601"],
         "connection" => ["keep-alive"],
         "content-type" => ["application/json"],
         "date" => ["Fri, 07 Jun 2024 13:53:39 GMT"],
         "expires" => ["0"],
         "pragma" => ["no-cache"],
         "vary" => ["Origin, Access-Control-Request-Method, Access-Control-Request-Headers"],
         "via" => ["1.1 varnish (Varnish/6.0)"],
         "x-content-type-options" => ["nosniff"],
         "x-frame-options" => ["DENY"],
         "x-varnish" => ["113873540"],
         "x-xss-protection" => ["1; mode=block"]
       },
       body: %{
         "category" => "EXTINCT",
         "code" => "EX",
         "iucnTaxonID" => "22690059",
         "scientificName" => "Raphus cucullatus (Linnaeus, 1758)",
         "taxonomicStatus" => "ACCEPTED",
         "usageKey" => 176_619_915
       },
       trailers: %{},
       private: %{}
     }}
  end

  def notify_infospecies_with_approval_result(_) do
    {:ok, %{body: "it's all fine", status: 200}}
  end
end
