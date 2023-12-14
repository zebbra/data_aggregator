defmodule DataAggregator.Records.Export.RunnerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Export.Runner

  import DataAggregator.ExportFixtures
  import DataAggregator.RecordsFixtures

  describe "DataAggregator.Records.Export.Runner.perform/1" do
    @valid_custom_mapping %{
      :mte_material_entity_id => "Numéro scientifique GBIF",
      :tax_family => "Famille"
    }

    setup do
      collection = Records.load!(collection_fixture(), [:records_to_publish_query])

      get_publishable_record(collection)
      get_publishable_record(collection)
      # this one should not be published
      get_unpublishable_record(collection)

      export =
        Export.create!(%{
          name: "export-#{collection.name}-#{Ecto.UUID.generate()}",
          collection: collection,
          mapping: @valid_custom_mapping,
          records_query: collection.records_to_publish_query
        })
        |> Collection.export!()

      [export: export]
    end

    test "succeeds with a valid mapping", %{
      export: export
    } do
      perform_job(Runner, %{id: export.id})

      export_with_attachment = Export.get_by_id!(export.id, load: [:attachment])

      assert export_with_attachment.attachment.url != nil
      assert export_with_attachment.state == :exported
      assert export_with_attachment.exported_at != nil
      assert export_with_attachment.finished_at != nil
    end
  end
end
