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
    mte_catalog_number: "encoded_record1",
    tax_scientific_name: "Anergates atratulus",
    tax_kingdom: "Animalia",
    tax_taxon_id: "2_435_194"
  }

  @doc """
    Generate a encoded_record.
  """
  def encoded_record_fixture(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put_new_lazy(:record, fn -> record_fixture() end)

    EncodedRecord.create!(params, tenant: params.record.collection, load: [:collection, :record])
  end

  @doc """
    Generate a record for encoding
  """
  def record_fixture_for_encoding(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:loc_state_province, "Bern")
      |> Map.put(:eve_event_date, "2025-01-01")
      |> Map.put(:loc_country, "Switzerland")
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end

  #### CoL Taxonomy API Encoding ####

  @doc """
    Generate a record for col_taxonomy encoding, which will lead to an invalid match type
  """
  def record_fixture_for_encoding_col_taxonomy_invalid(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:tax_scientific_name, "this leads to wrong match type")
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end

  #### CoL Taxonomy API Encoding ####

  @doc """
    Generate a record for iucn_redlist encoding with an extincted species
  """
  def record_fixture_for_encoding_iucn_redlist_extinct(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:tax_taxon_id, "2_496_198")
      |> Map.put(:tax_specific_epithet, "atratulus")
      |> Map.put(:tax_genus, "Anergates")
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end

  @doc """
    Generate a record for iucn_redlist encoding with an not evaluated species
  """
  def record_fixture_for_encoding_iucn_redlist_not_evaluated(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:tax_taxon_id, "2_496_298")
      |> Map.put(:tax_specific_epithet, "something_unknown")
      |> Map.put(:tax_genus, "something_unknown")
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end

  #### Swiss Species Catalog Encoding ####

  @doc """
    Generate a invalid record for swiss_species encoding
  """
  def record_fixture_for_encoding_swiss_species_invalid(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:tax_taxon_id, "0")
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end

  @doc """
    Generate a correct record for swiss_species encoding
  """
  def expect_correct_swiss_species_api_call(number \\ 1) do
    expect(SwissSpecies, :get_by_usage_key, number, fn _key ->
      {:ok,
       %SwissSpecies{
         id: "spc_02vSBcLj4G1ReRVJNXDLVo",
         taxon_id_ch: 15_311,
         accepted_name: "Enantiulus dentigerus (Verhoeff, 1901)",
         usage_key: "2_435_194",
         accepted_usage_key: 1_669_856,
         scientific_name: "Enantiulus dentigerus (Verhoeff, 1901)",
         rank: "SPECIES",
         center: "infofauna"
       }}
    end)
  end

  @doc """
    Generate a failing api call for swiss_species encoding
  """
  def expect_failing_swiss_species_api_call(number \\ 1) do
    expect(SwissSpecies, :get_by_usage_key, number, fn _key ->
      Logger.warning("unknown error occured")

      {:error, %Ash.Error.Unknown{}}
    end)
  end

  #### Geo Encoding API ####

  @doc """
    Generate a correct record for forward geo encoding (location to more location fields)
  """
  def record_fixture_for_forward_geo_encoding_correct(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:loc_state_province, "Bern")
      |> Map.put(:loc_country, "Switzerland")
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end

  @doc """
    Generate a correct record for reverse geo encoding (coords to location)
  """
  def record_fixture_for_reverse_geo_encoding_correct(attrs \\ %{}) do
    params =
      @encoded_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:loc_decimal_longitude, 7.104789)
      |> Map.put(:loc_decimal_latitude, 46.086797)
      |> Map.put_new_lazy(:collection, fn ->
        collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Record.create!(params, tenant: params.collection)
  end
end
