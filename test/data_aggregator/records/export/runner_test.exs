defmodule DataAggregator.Records.Export.RunnerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ExportFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export

  describe "DataAggregator.Records.Export.Exporter.perform/1" do
    @valid_custom_mapping %{
      :mte_catalog_number => "Numéro scientifique GBIF",
      :tax_family => "Famille"
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = Records.load!(collection_fixture(), [:records_to_export_query])

      exportable_record(collection)
      exportable_record(collection)
      # this one should not be exported if certain conditions are met
      unexportable_record(collection)

      export =
        %{
          name: "export-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
          collection: collection,
          mapping: @valid_custom_mapping,
          records_query: collection.records_to_export_query,
          data_layer: :raw,
          header_source: :custom_selection
        }
        |> Export.create!()
        |> Collection.export!()

      [export: export]
    end

    test "succeeds with a valid mapping", %{
      export: export
    } do
      perform_job(Export.Workers.Exporter, %{id: export.id})

      export_with_attachment = Export.get_by_id!(export.id, load: [:attachment])

      assert export_with_attachment.attachment.url != nil
      assert export_with_attachment.state == :exported
      assert export_with_attachment.exported_at != nil
      assert export_with_attachment.finished_at != nil
    end
  end
end
