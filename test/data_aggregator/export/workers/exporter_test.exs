defmodule DataAggregator.Records.Export.Workers.ExportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic.DSL

  import DataAggregator.ExportFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.Export

  describe "DataAggregator.Records.Export.Workers.Exporter.perform/1" do
    setup do
      collection = collection_fixture()

      publishable_record(collection)
      publishable_record(collection)

      export =
        Export.create!(%{
          name: "export-#{collection.name}-#{Ecto.UUID.generate()}",
          collection: collection,
          mapping: nil,
          records_query: collection.records_to_publish_query
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
