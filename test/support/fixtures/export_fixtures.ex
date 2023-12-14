defmodule DataAggregator.ExportFixtures do
  @moduledoc """
  This module defines test helpers for creating
  Publication entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Record

  import DataAggregator.RecordsFixtures

  @export_defaults %{
    name: "gbif.org - Export"
  }

  @doc """
  Generate an export.
  """
  def export_fixture(attrs \\ %{}) do
    collection = Records.load!(collection_fixture(), [:records_to_publish_query])

    @export_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection end)
    |> Map.put(:records_query, collection.records_to_publish_query)
    |> Export.create!()
  end

  def get_publishable_record(collection) do
    publishable_record_attrs()
    |> Map.put_new_lazy(:collection, fn -> collection end)
    |> Record.create!()
  end

  def get_unpublishable_record(collection) do
    publishable_record_attrs()
    |> Map.put_new_lazy(:collection, fn -> collection end)
    |> Map.delete(:tax_kingdom)
    |> Record.create!()
  end

  def publishable_record_attrs do
    %{
      mte_material_entity_id: "MHNG-MAM-8.085-#{Ecto.UUID.generate()}",
      tax_scientific_name: "Bradyphus Burmeister, 1866",
      tax_order: "Pilosa",
      tax_family: "Bradypodidae",
      tax_genus: "Bradypus",
      tax_kingdom: "Animalia",
      tax_taxon_id: "taxon-id-1"
    }
  end

  def create_export_with_mapping(collection, records, mapping) do
    %{
      name: "gbif.org - Export",
      collection: collection,
      records: records
    }
    |> Map.put(:records_query, collection.records_to_publish_query)
    |> Export.create!()
    |> Export.update_mapping(mapping)
  end
end
