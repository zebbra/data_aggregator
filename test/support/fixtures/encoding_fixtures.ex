defmodule DataAggregator.EncodingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """
  use ExUnit.Case, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  require Logger

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
    Generate a record for encoding
  """
  def record_fixture_for_encoding(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:loc_city, "Bern")
    |> Map.put(:loc_country, "Switzerland")
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  #### GBIF Taxonomy API Encoding ####

  @doc """
    Generate a record for gbif_taxonomy encoding, which will lead to an invalid match type
  """
  def record_fixture_for_encoding_gbif_taxonomy_invalid(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:tax_scientific_name, "this leads to wrong match type")
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  #### Swiss Species Catalog Encoding ####

  @doc """
    Generate a invalid record for swiss_species encoding
  """
  def record_fixture_for_encoding_swiss_species_invalid(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:tax_taxon_id, 0)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  @doc """
    Generate a correct record for swiss_species encoding
  """
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

  @doc """
    Generate a failing api call for swiss_species encoding
  """
  def expect_failing_swiss_species_api_call do
    expect(SwissSpecies, :get_by_usage_key, fn _key ->
      Logger.error("unknown error occured")

      {:error, %Ash.Error.Unknown{}}
    end)
  end

  #### Geo Encoding API ####

  @doc """
    Generate a correct record for forward geo encoding (location to more location fields)
  """
  def record_fixture_for_forward_geo_encoding_correct(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:loc_city, "Liebefeld")
    |> Map.put(:loc_municipality, nil)
    |> Map.put(:loc_state_province, "Bern")
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  @doc """
    Generate a correct record for reverse geo encoding (coords to location)
  """
  def record_fixture_for_reverse_geo_encoding_correct(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:loc_decimal_longitude, 7.456905642729698)
    |> Map.put(:loc_decimal_latitude, 46.946660986374766)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end
end
