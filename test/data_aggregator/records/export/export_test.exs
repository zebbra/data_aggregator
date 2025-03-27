defmodule DataAggregator.ExportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ExportFixtures
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Export.Workers.Exporter
  alias Explorer.DataFrame

  describe "export crud tests" do
    @invalid_attrs %{
      name: nil
    }
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      :ok
    end

    test "read!/0 returns all exports" do
      export_fixture_one = export_fixture()
      export_fixture_two = export_fixture(%{collection: export_fixture_one.collection})

      created = [
        export_fixture_one,
        export_fixture_two
      ]

      persisted = Export.read!(page: false, tenant: export_fixture_one.collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the export with given id" do
      created = export_fixture()
      persisted = Export.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 creates a export with valid data" do
      assert export_fixture()
    end

    test "create/1 with invalid data returns an error changeset" do
      assert {:error, %Invalid{}} = Export.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the export" do
      export = export_fixture()

      updated_export = %{
        name: "gbif.org_2",
        records: [
          record_fixture(%{collection: export.collection, mte_catalog_number: "record1"}),
          record_fixture(%{collection: export.collection, mte_catalog_number: "record2"})
        ]
      }

      assert {:ok, %Export{} = export} =
               export
               |> Export.update(updated_export)
               |> Ash.load([:collection])

      assert export.name == "gbif.org_2"
    end

    test "update/2 with invalid data fails and returns an error changeset" do
      assert {:error, %Invalid{}} =
               Export.update(export_fixture(), @invalid_attrs)
    end

    test "destroy/1 deletes a export" do
      export = export_fixture()
      assert :ok = Export.destroy(export, tenant: export.collection)

      assert_raise Ash.Error.Invalid, fn ->
        Export.get_by_id!(export.id, tenant: export.collection)
      end
    end

    test "destroy/1 with invalid id fails and returns an error changeset" do
      assert {:error, %Invalid{}} = Export.destroy(%Export{id: "invalid"})
    end
  end

  describe "enqueue/1" do
    @collection_mapping [
      %{name: "Scientific Name - collection", mapped_to: "tax_scientific_name"},
      %{name: "Numéro scientifique GBIF - collection", mapped_to: "mte_catalog_number"}
    ]

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection =
        Ash.load!(collection_fixture(%{import_mapping: @collection_mapping}), [
          :records_to_export_query
        ])

      collection_other = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})

      # those two should be exported
      exportable_record(collection)
      exportable_record(collection)
      # this one should not be exported
      unexportable_record(collection_other)

      export =
        Export.create!(
          %{
            name: "export-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
            collection: collection,
            mapping: nil,
            records_query: collection.records_to_export_query,
            data_layer: :raw,
            header_source: :collection_mapping
          },
          tenant: collection
        )

      [collection: collection, export: export]
    end

    test "enqueue/1 succeeds if collection state is idle", %{
      collection: collection,
      export: export
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, export} = Export.enqueue(export)

        assert export.state == :queued

        assert_enqueued(
          worker: Exporter,
          args: %{id: export.id, collection_id: export.collection_id}
        )

        collection = Collection.get_by_id!(collection.id)
        assert collection.state == :exporting
      end)
    end

    test "enqueue/1 fails if collection is in state importing", %{
      collection: collection,
      export: export
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_importing!(collection)
        assert_not_enqueued(export)
      end)
    end

    test "enqueue/1 fails if collection is in state exporting", %{
      collection: collection,
      export: export
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_exporting!(collection)
        assert_not_enqueued(export)
      end)
    end

    test "enqueue/1 fails if collection is in state encoding", %{
      collection: collection,
      export: export
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_encoding!(collection)
        assert_not_enqueued(export)
      end)
    end

    test "enqueue/1 fails if collection is in state validating", %{
      collection: collection,
      export: export
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_validating!(collection)
        assert_not_enqueued(export)
      end)
    end

    test "enqueue/1 fails if collection is in state fast_track_publishing", %{
      collection: collection,
      export: export
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_fast_track_publishing!(collection)
        assert_not_enqueued(export)
      end)
    end

    defp assert_not_enqueued(export) do
      assert {:error, %Invalid{}} = Export.enqueue(export, tenant: export.collection)
      export = Export.get_by_id!(export.id, tenant: export.collection)
      assert export.state == :pending
      refute_enqueued(worker: Exporter, args: %{id: export.id})
    end
  end

  describe "export" do
    @valid_custom_mapping %{
      "mte_catalog_number" => "Numéro scientifique GBIF",
      "tax_family" => "Famille"
    }

    @default_mapping Map.new(Schema.prefixed_attribute_names(), &{to_string(&1), to_string(&1)})

    @collection_mapping [
      %{name: "Scientific Name - collection", mapped_to: "tax_scientific_name"},
      %{name: "Numéro scientifique GBIF - collection", mapped_to: "mte_catalog_number"},
      %{name: "Custom Attribute", mapped_to: "Custom Attribute"}
    ]

    setup %{mapping: mapping, data_layer: data_layer, header_source: header_source} do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection =
        Ash.load!(collection_fixture(%{import_mapping: @collection_mapping}), [
          :records_to_export_query
        ])

      collection_other = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})

      # those two should be exported
      exportable_record(collection, %{
        extra_data: %{"Custom Attribute" => "Value 1"},
        mte_verbatim_label: "foo\nbar"
      })

      exportable_record(collection, %{
        extra_data: %{"Custom Attribute" => "Value 2"},
        mte_verbatim_label: nil
      })

      # this one should not be exported
      unexportable_record(collection_other)

      export =
        Export.create!(
          %{
            name: "export-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
            collection: collection,
            mapping: mapping,
            records_query: collection.records_to_export_query,
            data_layer: data_layer,
            header_source: header_source
          },
          tenant: collection
        )

      case Collection.export(export, tenant: collection) do
        {:ok, result} ->
          %{body: body} = Req.get!(result.attachment.url)

          {_, file_content} = Enum.at(body, 0)

          assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(file_content)

          [export: result, data_frame: data_frame]

        {:error, error} ->
          [error: error]
      end
    end

    @tag mapping: nil
    @tag data_layer: :raw
    @tag header_source: :custom_selection
    test "export records with no mapping, so default mapping should be used", %{
      export: export,
      data_frame: data_frame
    } do
      assert export.mapping == @default_mapping
      assert Explorer.DataFrame.n_columns(data_frame) == Enum.count(Map.keys(@default_mapping))
      assert Explorer.DataFrame.n_rows(data_frame) == 2
    end

    @tag mapping: @valid_custom_mapping
    @tag data_layer: :raw
    @tag header_source: :custom_selection
    test "export records with valid custom mapping", %{
      export: export,
      data_frame: data_frame
    } do
      assert export.mapping == @valid_custom_mapping
      assert Explorer.DataFrame.n_columns(data_frame) == 2
      assert Explorer.DataFrame.n_rows(data_frame) == 2

      assert_lists_equal(Explorer.DataFrame.names(data_frame), [
        "Famille",
        "Numéro scientifique GBIF"
      ])
    end

    @tag mapping: nil
    @tag data_layer: :raw
    @tag header_source: :collection_mapping
    test "export records with datalayer :raw, header_source :collection_mapping", %{
      export: export,
      data_frame: data_frame
    } do
      assert export.mapping == %{
               "mte_catalog_number" => "Numéro scientifique GBIF - collection",
               "tax_scientific_name" => "Scientific Name - collection",
               "Custom Attribute" => "Custom Attribute"
             }

      assert columns = Explorer.DataFrame.names(data_frame)

      assert Enum.member?(columns, "Numéro scientifique GBIF - collection")
      assert Enum.member?(columns, "Scientific Name - collection")
      assert Enum.member?(columns, "Custom Attribute")

      assert Explorer.DataFrame.n_columns(data_frame) == 3
      assert Explorer.DataFrame.n_rows(data_frame) == 2

      custom_attribute_values =
        data_frame
        |> Explorer.DataFrame.to_rows()
        |> Enum.map(&Map.get(&1, "Custom Attribute"))

      assert custom_attribute_values == ["Value 1", "Value 2"]
    end

    @tag mapping: nil
    @tag data_layer: :raw
    @tag header_source: :dwc_attributes
    test "transforms values according to the transformers", %{data_frame: data_frame} do
      rows = Explorer.DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(rows, &Map.take(&1, ["decimalLongitude", "decimalLatitude"]))

      expected = [
        %{"decimalLatitude" => 46.8182, "decimalLongitude" => 640_000},
        %{"decimalLatitude" => 46.8182, "decimalLongitude" => 640_000}
      ]

      assert expected == transformed_attributes
    end

    @tag mapping: nil
    @tag data_layer: :raw
    @tag header_source: :dwc_attributes
    test "replaces linebreaks", %{data_frame: data_frame} do
      rows = Explorer.DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(rows, &Map.take(&1, ["verbatimLabel"]))

      expected = [
        %{"verbatimLabel" => "foo bar"},
        %{"verbatimLabel" => nil}
      ]

      assert expected == transformed_attributes
    end

    @tag mapping: nil
    @tag data_layer: :raw
    @tag header_source: :dwc_attributes
    test "gets values from collection", %{export: export, data_frame: data_frame} do
      rows = Explorer.DataFrame.to_rows(data_frame)

      collection_attributes =
        Enum.map(
          rows,
          &Map.take(&1, [
            "collectionID",
            "collectionCode",
            "institutionCode",
            "institutionID",
            "datasetID",
            "gbifDOI"
          ])
        )

      expected = [
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => nil,
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33",
          "gbifDOI" => nil
        },
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => nil,
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33",
          "gbifDOI" => nil
        }
      ]

      assert expected == collection_attributes

      Ash.update(export.collection, %{
        gbif_doi: "10.21373/dmvukj",
        gbif_dataset_key: "1234-1234-1234-1234"
      })

      export = Ash.load!(export, [:collection])
      {:ok, export} = Collection.export(export, tenant: export.collection)

      %{body: body} = Req.get!(export.attachment.url)

      {_, file_content} = Enum.at(body, 0)

      assert {:ok, %DataFrame{} = new_data_frame} = DataFrame.load_csv(file_content)
      new_rows = Explorer.DataFrame.to_rows(new_data_frame)

      collection_attributes =
        Enum.map(
          new_rows,
          &Map.take(&1, [
            "collectionID",
            "collectionCode",
            "institutionCode",
            "institutionID",
            "datasetID",
            "gbifDOI"
          ])
        )

      expected = [
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33",
          "gbifDOI" => "10.21373/dmvukj"
        },
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33",
          "gbifDOI" => "10.21373/dmvukj"
        }
      ]

      assert expected == collection_attributes
    end

    @tag mapping: nil
    @tag data_layer: :encoded
    @tag header_source: :collection_mapping
    test "export records with datalayer :encoded, header_source :collection_mapping", %{
      export: export,
      data_frame: data_frame
    } do
      # ensure custom mapping is also exported
      assert export.mapping == %{
               "mte_catalog_number" => "Numéro scientifique GBIF - collection",
               "tax_scientific_name" => "Scientific Name - collection",
               "Custom Attribute" => "Custom Attribute"
             }

      assert columns = Explorer.DataFrame.names(data_frame)

      assert Enum.member?(columns, "Numéro scientifique GBIF - collection")
      assert Enum.member?(columns, "Scientific Name - collection")
      assert Enum.member?(columns, "Custom Attribute")

      assert Explorer.DataFrame.n_columns(data_frame) == 3
      assert Explorer.DataFrame.n_rows(data_frame) == 2
    end

    @tag mapping: nil
    @tag data_layer: :raw
    @tag header_source: :dwc_attributes
    test "export records with datalayer :raw, header_source :dwc_attributes", %{
      export: export,
      data_frame: data_frame
    } do
      assert export.mapping == expected_dwc_attribute_mapping()

      assert_lists_equal(Explorer.DataFrame.names(data_frame), expected_dwc_column_headers())

      assert Explorer.DataFrame.n_columns(data_frame) == 292
      assert Explorer.DataFrame.n_rows(data_frame) == 2
    end

    @tag mapping: nil
    @tag data_layer: :encoded
    @tag header_source: :dwc_attributes
    test "export records with datalayer :encoded, header_source :dwc_attributes", %{
      export: export,
      data_frame: data_frame
    } do
      assert export.mapping == expected_dwc_attribute_mapping()

      assert_lists_equal(Explorer.DataFrame.names(data_frame), expected_dwc_column_headers())

      assert Explorer.DataFrame.n_columns(data_frame) == 292
      assert Explorer.DataFrame.n_rows(data_frame) == 2
    end
  end
end
