defmodule DataAggregator.Platform.Publication.Export.RunnerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Platform.Publication.Export.Runner
  alias DataAggregator.Records.Collection

  import DataAggregator.PublicationFixtures
  import DataAggregator.RecordsFixtures

  @tag run: true
  describe "DataAggregator.Platform.Publication.Export.Runner.perform/1" do
    @valid_custom_mapping %{
      :mte_material_entity_id => "Numéro scientifique GBIF",
      :tax_family => "Famille"
    }

    setup do
      collection = collection_fixture()

      get_publishable_record(collection)
      get_publishable_record(collection)
      # this one should not be published
      get_unpublishable_record(collection)

      records = Collection.collect_reviewable_records!(collection)

      {:ok, export} =
        %{
          name: "gbif.org - Export",
          collection: collection,
          records: records
        }
        |> Export.create!()
        |> Export.update_mapping(@valid_custom_mapping)

      [export: export]
    end

    test "succeeds with a valid mapping", %{
      export: export
    } do
      perform_job(Runner, %{id: export.id})

      export_with_attachment = Export.get_by_id!(export.id, load: [:attachment, :records_count])

      assert export_with_attachment.attachment.url != nil
      assert export_with_attachment.records_count == 2
      assert export_with_attachment.state == :exported
      assert export_with_attachment.exported_at != nil
      assert export_with_attachment.finished_at != nil
    end
  end
end
