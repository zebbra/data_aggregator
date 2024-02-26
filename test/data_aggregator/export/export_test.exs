defmodule DataAggregator.ExportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  import DataAggregator.ExportFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export

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
        collection: collection_fixture(),
        records: [
          record_fixture(),
          record_fixture()
        ]
      }

      assert {:ok, %Export{} = export} =
               export
               |> Export.update(updated_export)
               |> Records.load([:collection])

      assert export.name == "gbif.org_2"
    end

    test "update/2 with invalid data fails and returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} =
               Export.update(export_fixture(), @invalid_attrs)
    end

    test "destroy/1 deletes a export" do
      export = export_fixture()
      assert :ok = Export.destroy(export)
      assert_raise Ash.Error.Query.NotFound, fn -> Export.get_by_id!(export.id) end
    end

    test "destroy/1 with invalid id fails and returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Export.destroy(%Export{id: "invalid"})
    end
  end

  describe "export" do
    @valid_custom_mapping %{
      "mte_material_entity_id" => "Numéro scientifique GBIF",
      "tax_family" => "Famille"
    }
    @default_mapping Map.new(Schema.prefixed_attribute_names(), fn name ->
                       {name, Atom.to_string(name)}
                     end)

    setup %{mapping: mapping} do
      collection = Records.load!(collection_fixture(), [:records_to_publish_query])

      # those two should be published
      get_publishable_record(collection)
      get_publishable_record(collection)
      # this one should not be published
      get_unpublishable_record(collection)

      export =
        Export.create!(%{
          name: "export-#{collection.name}-#{Ecto.UUID.generate()}",
          collection: collection,
          mapping: mapping,
          records_query: collection.records_to_publish_query
        })

      case Collection.export(export) do
        {:ok, result} -> [export: result]
        {:error, error} -> [error: error]
      end
    end

    @tag mapping: nil
    test "export records with no mapping, so default mapping should be used", %{
      export: export
    } do
      df = Explorer.DataFrame.from_csv!(export.attachment.url)

      assert export.mapping == @default_mapping

      assert Explorer.DataFrame.n_columns(df) == Enum.count(Map.keys(@default_mapping))

      assert Explorer.DataFrame.n_rows(df) == 3
    end

    @tag mapping: @valid_custom_mapping
    test "export records with valid custom mapping", %{
      export: export
    } do
      df = Explorer.DataFrame.from_csv!(export.attachment.url)

      assert export.mapping == @valid_custom_mapping

      assert Explorer.DataFrame.n_columns(df) == 2

      assert Explorer.DataFrame.n_rows(df) == 3
    end
  end
end
