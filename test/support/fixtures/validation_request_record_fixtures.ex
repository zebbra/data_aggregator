defmodule DataAggregator.ValidationRequestRecordFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records.ValidationRequestRecord` context.
  """

  alias DataAggregator.Records.ValidationRequestRecord

  @validation_request_record_defaults %{
    data: %{
      mte_catalog_number: "MHNG-MAM-8.085-test",
      tax_scientific_name: "Bradypus variegatus",
      tax_order: "Pilosa",
      tax_family: "Bradypodidae",
      tax_genus: "Bradypus",
      tax_kingdom: "Animalia",
      tax_taxon_id: 2_435_194,
      loc_decimal_latitude: 46.8182,
      loc_decimal_longitude: 640_000.0,
      ext_assertions: %{"1" => 1}
    }
  }

  @doc """
  Generate a validation request record
  """
  def validation_request_record_fixture(attrs \\ %{}) do
    collection = attrs[:collection]
    record = attrs[:record]

    params =
      @validation_request_record_defaults
      |> Map.merge(attrs)
      |> Map.put(:collection, collection)
      |> Map.put(:record, record)

    ValidationRequestRecord.create!(params, tenant: collection)
  end

  @doc """
  Generate validation request record data with Darwin Core attributes
  """
  def validation_request_data_fixture(attrs \\ %{}) do
    base_data = %{
      "mte_catalog_number" => "MHNG-MAM-8.085-#{Uniq.UUID.uuid7(:slug)}",
      "tax_scientific_name" => "Bradypus variegatus",
      "tax_order" => "Pilosa",
      "tax_family" => "Bradypodidae",
      "tax_genus" => "Bradypus",
      "tax_kingdom" => "Animalia",
      "tax_taxon_id" => 2_435_194,
      "loc_decimal_latitude" => 46.8182,
      "loc_decimal_longitude" => 640_000.0,
      "ext_assertions" => %{"1" => 1},
      "occ_occurrence_id" => "occurrence-#{Ecto.UUID.generate()}",
      "eve_event_date" => "2023-01-15",
      "loc_country" => "Switzerland",
      "loc_locality" => "Geneva",
      "prs_first_name" => "John",
      "prs_last_name" => "Doe",
      "prs_date_of_birth" => "1980-01-01",
      "ref_bibliographic_citation" => "Test Reference",
      "ref_creator" => "Test Creator",
      "ref_title" => "Test Title"
    }

    Map.merge(base_data, attrs)
  end
end
