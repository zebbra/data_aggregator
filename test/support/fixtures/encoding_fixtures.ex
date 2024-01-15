defmodule DataAggregator.EncodingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """
  use ExUnit.Case, async: true
  use Mimic

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  import DataAggregator.RecordsFixtures

  @encoded_record_defaults %{
    mte_material_entity_id: "encoded_record1",
    tax_scientific_name: "Oenanthea Pallas",
    tax_kingdom: "Animalia",
    tax_taxon_id: 1_012_187
  }

  @doc """
    Generate a encoded_record.
  """
  def encoded_record_fixture(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:record, fn -> record_fixture() end)
    |> EncodedRecord.create!()
  end

  @doc """
    Generate a record for encoding process
  """
  def record_fixture_for_encoding(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  @doc """
    Generate a record for encoding process, which will lead to an invalid confidence
  """
  def record_fixture_for_encoding_invalid_confidence(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:tax_scientific_name, "this leads to wrong confidence")
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  @doc """
    Generate a record for encoding process, which will lead to an invalid confidence
  """
  def record_fixture_for_encoding_swiss_species(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:tax_taxon_id, 0)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  # "confidence" => 79 is below the minimum confidence level of 80
  def response_body_with_invalid_confidence do
    %{
      "acceptedUsageKey" => 2_492_483,
      "canonicalName" => "Oenanthe",
      "class" => "Aves",
      "classKey" => 212,
      "confidence" => 79,
      "family" => "Muscicapidae",
      "familyKey" => 9322,
      "genus" => "Oenanthe",
      "genusKey" => 2_492_483,
      "kingdom" => "Animalia",
      "kingdomKey" => 1,
      "matchType" => "FUZZY",
      "order" => "Passeriformes",
      "orderKey" => 729,
      "phylum" => "Chordata",
      "phylumKey" => 44,
      "rank" => "GENUS",
      "scientificName" => "Oenanthe Pallas, 1771",
      "status" => "SYNONYM",
      "synonym" => true,
      "usageKey" => 7_984_973
    }
  end

  def correct_match_api_response_body do
    %{
      "acceptedUsageKey" => 2_492_483,
      "canonicalName" => "Oenanthe",
      "class" => "Aves",
      "classKey" => 212,
      "confidence" => 88,
      "family" => "Muscicapidae",
      "familyKey" => 9322,
      "genus" => "Oenanthe",
      "genusKey" => 2_492_483,
      "kingdom" => "Animalia",
      "kingdomKey" => 1,
      "matchType" => "FUZZY",
      "order" => "Passeriformes",
      "orderKey" => 729,
      "phylum" => "Chordata",
      "phylumKey" => 44,
      "rank" => "GENUS",
      "scientificName" => "Oenanthe Pallas, 1771",
      "status" => "SYNONYM",
      "synonym" => true,
      "usageKey" => 7_984_973
    }
  end

  def correct_species_api_response_body do
    %{
      "orderKey" => 729,
      "kingdom" => "Animalia",
      "numDescendants" => 111,
      "rank" => "GENUS",
      "nameType" => "SCIENTIFIC",
      "lastCrawled" => "2023-08-22T23:20:59.545+00:00",
      "parent" => "Muscicapidae",
      "canonicalName" => "Oenanthe",
      "taxonID" => "gbif:2492483",
      "key" => 2_492_483,
      "genus" => "Oenanthe",
      "family" => "Muscicapidae",
      "authorship" => "Vieillot, 1816",
      "origin" => "SOURCE",
      "genusKey" => 2_492_483,
      "kingdomKey" => 1,
      "constituentKey" => "7ddf754f-d193-4cc9-b351-99906754a03b",
      "scientificName" => "Oenanthe Vieillot, 1816",
      "lastInterpreted" => "2023-08-22T22:19:29.194+00:00",
      "order" => "Passeriformes",
      "taxonomicStatus" => "ACCEPTED",
      "class" => "Aves",
      "remarks" => "",
      "parentKey" => 9322,
      "nameKey" => 7_724_841,
      "publishedIn" =>
        "Vieillot, Louis P. 1816. Analyse d'une nouvelle ornithologie élémentaire. Deterville, Paris.: 1-70.",
      "nubKey" => 2_492_483,
      "classKey" => 212,
      "familyKey" => 9322,
      "nomenclaturalStatus" => [],
      "datasetKey" => "d7dddbf4-2cf0-4f39-9b2a-bb099caae36c",
      "sourceTaxonKey" => 172_764_999,
      "phylumKey" => 44,
      "issues" => [],
      "vernacularName" => "wheatear",
      "phylum" => "Chordata"
    }
  end

  # this mocks the call to the match api --> https://api.gbif.org/v1/species/match
  def expect_correct_matching_api_call do
    url = GbifTaxonomyStrategy.match_api_url()

    expect(Req, :get, fn ^url, [params: [name: "Oenanthea Pallas", kingdom: "Animalia"]] ->
      {:ok,
       %{
         status: 200,
         body: correct_match_api_response_body()
       }}
    end)
  end

  # this mocks the call to the species api --> https://api.gbif.org/v1/species/2492483
  # because the response of the matching api above indicates, that the record is a synonym,
  # the accepted species is fetched from the species api and therefore mocked here
  def expect_correct_species_api_call do
    url = "#{GbifTaxonomyStrategy.species_api_url()}/2492483"

    expect(Req, :get, fn ^url, [params: []] ->
      {:ok,
       %{
         status: 200,
         body: correct_species_api_response_body()
       }}
    end)
  end

  # this mocks the call to the match api --> https://api.gbif.org/v1/species/match
  # we expect an incorrect confidence level in the response body
  def expect_invalid_confidence_from_matching_api_call do
    url = GbifTaxonomyStrategy.match_api_url()

    expect(Req, :get, fn ^url,
                         [params: [name: "this leads to wrong confidence", kingdom: "Animalia"]] ->
      {:ok,
       %{
         status: 200,
         body: response_body_with_invalid_confidence()
       }}
    end)
  end

  def expect_correct_swiss_species_api_call do
    expect(SwissSpecies, :get_by_usage_key, fn _key ->
      {:ok,
       %SwissSpecies{
         id: "spc_02vSBcLj4G1ReRVJNXDLVo",
         taxon_id_ch: 15_311,
         accepted_name: "Enantiulus dentigerus (Verhoeff, 1901)",
         usage_key: 1_012_187,
         accepted_usage_key: nil,
         scientific_name: "Enantiulus dentigerus (Verhoeff, 1901)",
         rank: "SPECIES"
       }}
    end)
  end
end
