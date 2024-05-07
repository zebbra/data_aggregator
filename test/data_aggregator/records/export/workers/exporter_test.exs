defmodule DataAggregator.Records.Export.Workers.ExportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic.DSL

  import DataAggregator.ExportFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.Export

  @mapping %{
    "mte_catalog_number" => "Numéro scientifique GBIF",
    "tax_family" => "Famille"
  }

  describe "DataAggregator.Records.Export.Workers.Exporter.perform/1" do
    setup do
      collection = collection_fixture()

      exportable_record(collection)
      exportable_record(collection)

      export =
        Export.create!(%{
          name: "export-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
          collection: collection,
          mapping: @mapping,
          records_query: collection.records_to_export_query,
          data_layer: :raw,
          header_source: :custom_selection
        })

      [export: export]
    end

    test "export success", %{export: export} do
      perform_job(Export.Workers.Exporter, %{id: export.id})

      export = Export.get_by_id!(export.id)

      assert export.state == :exported
      assert export.exported_count == 2
    end
  end
end
