defmodule DataAggregator.ExportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Platform.Publication.Consumer
  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  import DataAggregator.PublicationFixtures
  import DataAggregator.RecordsFixtures

  describe "export crud tests" do
    @invalid_attrs %{
      name: nil
    }

    test "read!/0 returns all exports" do
      created = [
        export_fixture(),
        export_fixture()
      ]

      persisted = Export.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the export with given id" do
      created = export_fixture()
      persisted = Export.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 creates a export with valid data" do
      assert export_fixture()
    end

    test "create/1 with invalid data returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Export.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the export" do
      export = export_fixture()

      updated_export = %{
        name: "gbif.org_2",
        consumer: consumer_fixture(),
        records: [
          record_fixture(),
          record_fixture()
        ]
      }

      assert {:ok, %Export{} = export} =
               export
               |> Export.update(updated_export)
               |> DataAggregator.Platform.load([:consumer, :records_count])

      assert export.records_count == 2
      assert export.name == "gbif.org_2"
    end

    test "update/2 with invalid data fails and returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} =
               export_fixture() |> Export.update(@invalid_attrs)
    end

    test "destroy/1 deletes a export" do
      export = export_fixture()
      assert :ok = Export.destroy(export)
      assert_raise Ash.Error.Query.NotFound, fn -> Export.get_by_id!(export.id) end
    end

    test "destroy/1 with invalid id fails and returns an error changeset" do
      assert {:error, %Ash.Error.Unknown{}} = Export.destroy(%Export{id: "invalid"})
    end
  end

  setup do
    {:ok, collection} =
      Collection.create(%{name: "Collection for Publication", owner: "David Attenborough"})

    %{collection: collection}
  end

  @tag run: true
  describe "publication" do
    test "publish records for export" do
      # arrange

      # those two should be published
      get_publishable_record()
      get_publishable_record()
      # this one should not be published
      get_unpublishable_record()

      consumer = consumer_fixture()

      # act
      collected_records = consumer |> Consumer.collect!()

      export =
        %{
          name: "gbif.org - Export",
          consumer: consumer,
          records: collected_records
        }
        |> Export.create!()
        |> Export.update_mapping!(nil)

      {:ok, attachment} = export |> Export.publish()

      # assert
      # ensure (default) mapping was set
      assert export.mapping == nil
      # there should be a valid df created from the csv under the url
      df = Explorer.DataFrame.from_csv!(attachment.url)
      # there should be multiple columns in the resulting dataframe / csv file
      assert df |> Explorer.DataFrame.n_columns() > 0
      # only two records should be published
      assert df |> Explorer.DataFrame.n_rows() == 2
    end
  end

  defp get_publishable_record do
    publishable_record_attrs()
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end

  defp get_unpublishable_record do
    publishable_record_attrs()
    |> Map.delete(:tax_kingdom)
  end

  defp publishable_record_attrs do
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
end
