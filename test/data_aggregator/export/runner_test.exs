defmodule DataAggregator.Platform.Publication.Export.RunnerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Platform.Publication.Export.Runner
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection

  import DataAggregator.PublicationFixtures
  import DataAggregator.RecordsFixtures

  describe "DataAggregator.Platform.Publication.Export.Runner.perform/1" do
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
          mapping: @valid_custom_mapping
        })
        |> Collection.export!(collection.records_to_publish_query)

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
