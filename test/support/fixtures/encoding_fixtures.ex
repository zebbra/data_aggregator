defmodule DataAggregator.EncodingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """
  use ExUnit.Case, async: true
  use Mimic

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  import DataAggregator.RecordsFixtures

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
    Generate a record for encoding process
  """
  def record_fixture_for_encoding(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  @doc """
    Generate a record for gbif_taxonomy encoding process, which will lead to an invalid match type
  """
  def record_fixture_for_encoding_gbif_taxonomy_invalid(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:tax_scientific_name, "this leads to wrong match type")
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  @doc """
    Generate a record for swiss_species encoding process
  """
  def record_fixture_for_encoding_swiss_species_invalid(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put(:tax_taxon_id, 0)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
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

  def expect_failing_swiss_species_api_call do
    expect(SwissSpecies, :get_by_usage_key, fn _key ->
      Logger.error("unknown error occured")

      {:error, %Ash.Error.Unknown{}}
    end)
  end
end
