defmodule DataAggregator.EncodingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  import DataAggregator.RecordsFixtures

  @encoded_record_defaults %{
    mte_material_entity_id: "encoded_record1",
    tax_scientific_name: "Oenanthe Pallas, 1771",
    tax_kingdom: "Animalia"
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

  def record_fixture_for_encoding(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

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
      "matchType" => "EXACT",
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

  def correct_response_body do
    %{
      "acceptedUsageKey" => 2_492_483,
      "canonicalName" => "Oenanthe",
      "class" => "Aves",
      "classKey" => 212,
      "confidence" => 97,
      "family" => "Muscicapidae",
      "familyKey" => 9322,
      "genus" => "Oenanthe",
      "genusKey" => 2_492_483,
      "kingdom" => "Animalia",
      "kingdomKey" => 1,
      "matchType" => "EXACT",
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
end
