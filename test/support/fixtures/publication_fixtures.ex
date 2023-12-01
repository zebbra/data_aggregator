defmodule DataAggregator.PublicationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  Consumer entities via the `DataAggregator.Platform` context.
  """

  alias DataAggregator.Platform.Publication.Consumer
  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Records.Record

  import DataAggregator.RecordsFixtures

  @consumers_defaults %{
    name: "gbif.org",
    publication_type: :gbif
  }

  @export_defaults %{
    name: "gbif.org - Export"
  }

  @doc """
  Generate a consumer.
  """
  def consumer_fixture(attrs \\ %{}) do
    @consumers_defaults
    |> Map.merge(attrs)
    |> Consumer.create!()
  end

  @doc """
  Generate an export.
  """
  def export_fixture(attrs \\ %{}) do
    @export_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:consumer, fn -> consumer_fixture() end)
    |> Map.put(:records, [])
    |> Export.create!()
  end

  def get_publishable_record do
    publishable_record_attrs()
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  def get_unpublishable_record do
    publishable_record_attrs()
    |> Map.delete(:tax_kingdom)
  end

  def publishable_record_attrs do
    %{
      mte_material_entity_id: "MHNG-MAM-8.085",
      tax_scientific_name: "Bradyphus Burmeister, 1866",
      tax_order: "Pilosa",
      tax_family: "Bradypodidae",
      tax_genus: "Bradypus",
      tax_kingdom: "Animalia",
      tax_taxon_id: "taxon-id-1"
    }
  end

  def create_export_with_mapping(consumer, records, mapping) do
    %{
      name: "gbif.org - Export",
      consumer: consumer,
      records: records
    }
    |> Export.create!()
    |> Export.update_mapping(mapping)
  end
end
