defmodule DataAggregator.PublicationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Gbif
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Publication.Workers.Publisher
  alias DataAggregator.Records.Record
  alias Explorer.DataFrame

  require Ash.Query

  describe "publication tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      collection_append =
        collection_fixture(%{
          name: "Collection append test",
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      collection_register_collection_failing =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.register_collection_fail_grscicoll_reference()
        })

      collection_create_endpoint_failing =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.create_endpoint_fail_grscicoll_reference()
        })

      collection_get_endpoints_failing =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.get_endpoints_fail_grscicoll_reference()
        })

      collection_delete_endpoint_failing =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.delete_endpoint_fail_grscicoll_reference()
        })

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 10.0,
          loc_decimal_longitude: 10.0
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 166.4713889,
          loc_decimal_longitude: 640_000.0
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 47.27606815,
          loc_decimal_longitude: 9.408043484
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })

      record_append_1 =
        record_fixture(%{
          collection: collection_append,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record_append_2 =
        record_fixture(%{
          collection: collection_append,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })

      record_append_3 =
        record_fixture(%{
          collection: collection_append,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})
      encoded_record_append_1 = encoded_record_fixture(%{record: record_append_1})
      encoded_record_append_1 |> Ash.update!(%{tax_taxon_id: 4762}) |> Map.get(:tax_taxon_id)
      encoded_record_fixture(%{record: record_append_2})
      encoded_record_fixture(%{record: record_append_3})

      records = [
        Ash.load!(record1, [:encoded_record]),
        Ash.load!(record2, [:encoded_record]),
        Ash.load!(record3, [:encoded_record]),
        Ash.load!(record4, [:encoded_record]),
        Ash.load!(record5, [:encoded_record]),
        Ash.load!(record_append_1, [:encoded_record]),
        Ash.load!(record_append_2, [:encoded_record]),
        Ash.load!(record_append_3, [:encoded_record])
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      query_append_1 = %{
        collection: %{id: %{eq: collection_append.id}},
        encoded_record: %{tax_kingdom: %{eq: "Animalia"}}
      }

      query_append_2 = %{
        collection: %{id: %{eq: collection_append.id}},
        encoded_record: %{tax_kingdom: %{eq: "My Kingdom"}}
      }

      query_append_3 = %{
        collection: %{id: %{eq: collection_append.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      publication =
        Publication.create!(
          %{
            name: "Publication Fast Track 2",
            channel: :fast_track,
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      publicatoin_1 =
        Publication.create!(
          %{
            name: "Publication register collection failing",
            channel: :fast_track,
            records_query: query,
            collection: collection_register_collection_failing
          },
          tenant: collection_register_collection_failing
        )

      publication_2 =
        Publication.create!(
          %{
            name: "Publication create endpoint failing",
            channel: :fast_track,
            records_query: query,
            collection: collection_create_endpoint_failing
          },
          tenant: collection_create_endpoint_failing
        )

      publication_3 =
        Publication.create!(
          %{
            name: "Publication get endpoints failing, delete endpoint failing",
            channel: :fast_track,
            records_query: query,
            collection: collection_get_endpoints_failing
          },
          tenant: collection_get_endpoints_failing
        )

      publication_4 =
        Publication.create!(
          %{
            name: "Publication get endpoints success, delete endpoint failing",
            channel: :fast_track,
            records_query: query,
            collection: collection_delete_endpoint_failing
          },
          tenant: collection_delete_endpoint_failing
        )

      publication_append_1 =
        Publication.create!(
          %{
            name: "Publication Fast Track append test",
            channel: :fast_track,
            records_query: query_append_1,
            collection: collection_append
          },
          tenant: collection_append
        )

      publication_append_2 =
        Publication.create!(
          %{
            name: "Publication Fast Track append test",
            channel: :fast_track,
            records_query: query_append_2,
            collection: collection_append
          },
          tenant: collection_append
        )

      publication_append_3 =
        Publication.create!(
          %{
            name: "Publication Fast Track append test",
            channel: :fast_track,
            layer: "import",
            records_query: query_append_3,
            collection: collection_append
          },
          tenant: collection_append
        )

      [
        collection: collection,
        records: records,
        publication: publication,
        publication_1: publicatoin_1,
        publication_2: publication_2,
        publication_3: publication_3,
        publication_4: publication_4,
        publication_append_1: publication_append_1,
        publication_append_2: publication_append_2,
        publication_append_3: publication_append_3
      ]
    end

    test "publish/1 successful", %{
      publication: publication
    } do
      {:ok, publication} = Collection.publish(publication, tenant: publication.collection)

      %{body: body} = Req.get!(publication.attachment.url)

      # validating if the core file is correctly created
      {core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert core_file_name != nil
      assert core_file_content != nil

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(core_file_content)

      assert_lists_equal(
        data_frame.names,
        DwcaFile.file_header_fields(:core),
        fn a, b -> a == b end
      )

      assert DataFrame.n_rows(data_frame) == 5

      rows = DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(rows, &Map.take(&1, ["decimalLongitude", "decimalLatitude"]))

      expected = [
        %{"decimalLatitude" => 10.0, "decimalLongitude" => 10.0},
        %{"decimalLatitude" => 166.4713889, "decimalLongitude" => 640_000.0},
        %{"decimalLatitude" => 47.27606815, "decimalLongitude" => 9.408043484},
        %{"decimalLatitude" => nil, "decimalLongitude" => nil},
        %{"decimalLatitude" => nil, "decimalLongitude" => nil}
      ]

      assert_lists_equal(expected, transformed_attributes)
    end

    test "publish/1 successful with correct appending of data", %{
      publication_append_1: publication_1,
      publication_append_2: publication_2,
      publication_append_3: publication_3
    } do
      {:ok, publication_1} =
        Collection.publish(publication_1, tenant: publication_1.collection)

      %{body: body} = Req.get!(publication_1.attachment.url)

      # validate core file from first publication
      {_core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(core_file_content)

      query_publication_1 =
        Record
        |> AshPagify.query_for_filters_map(publication_1.records_query)
        |> Ash.Query.set_tenant(publication_1.collection)

      # the query should return 1 record
      assert query_publication_1 |> Ash.read!() |> length() == 1
      # and the core file should have 1 row
      assert DataFrame.n_rows(data_frame) == 1

      published_records = Ash.read!(PublishedRecord, tenant: publication_1.collection)
      assert length(published_records) == 1

      # default publication is on layer 'approval' so the value saved in published_records are the encoded_record values
      assert published_records |> List.first() |> Map.get(:tax_taxon_id) == 4762
      rows = DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(rows, &Map.take(&1, ["taxonID"]))

      expected = [
        %{"taxonID" => 4762}
      ]

      assert_lists_equal(expected, transformed_attributes)

      {:ok, publication_2} =
        Collection.publish(publication_2, tenant: publication_2.collection)

      %{body: body} = Req.get!(publication_2.attachment.url)

      # validate core file from second publication
      {_core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(core_file_content)

      query_publication_2 =
        Record
        |> AshPagify.query_for_filters_map(publication_2.records_query)
        |> Ash.Query.set_tenant(publication_2.collection)

      # the query should return 2 records
      assert query_publication_2 |> Ash.read!() |> length() == 2
      # but because we are appending the data, the core file should have 3 rows
      assert DataFrame.n_rows(data_frame) == 3

      published_records = Ash.read!(PublishedRecord, tenant: publication_2.collection)
      assert length(published_records) == 3

      # the record published first should still use the value from encoded record
      assert published_records |> List.first() |> Map.get(:tax_taxon_id) == 4762
      rows = DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(rows, &Map.take(&1, ["taxonID"]))

      expected = [
        %{"taxonID" => 4762},
        %{"taxonID" => nil},
        %{"taxonID" => nil}
      ]

      assert_lists_equal(expected, transformed_attributes)

      # now we publish a publication with all 3 records again, but on the 'import' layer
      {:ok, publication_3} =
        Collection.publish(publication_3, tenant: publication_3.collection)

      %{body: body} = Req.get!(publication_3.attachment.url)

      # validate core file from third publication
      {_core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(core_file_content)

      query_publication_3 =
        Record
        |> AshPagify.query_for_filters_map(publication_3.records_query)
        |> Ash.Query.set_tenant(publication_3.collection)

      # the query should return 3 records
      assert query_publication_3 |> Ash.read!() |> length() == 3
      # these records got upserted, but on the 'import' layer, so the core file should have 3 rows
      assert DataFrame.n_rows(data_frame) == 3

      published_records = Ash.read!(PublishedRecord, tenant: publication_3.collection)
      assert length(published_records) == 3
      # the tax_taxon_id is nil, because its on the import layer
      assert published_records |> List.first() |> Map.get(:tax_taxon_id) == nil
      rows = DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(rows, &Map.take(&1, ["taxonID"]))

      expected = [
        %{"taxonID" => nil},
        %{"taxonID" => nil},
        %{"taxonID" => nil}
      ]

      assert_lists_equal(expected, transformed_attributes)
    end

    test "publish/1 succesful with publication rules", %{
      publication: publication,
      records: records
    } do
      expect_correct_swiss_species_api_call(2)

      update_record_fixtures!(Enum.at(records, 0), %{
        tax_taxon_id: 4762,
        loc_decimal_latitude: 48.27606815,
        loc_decimal_longitude: 10.408043484
      })

      update_record_fixtures!(Enum.at(records, 1), %{
        tax_taxon_id: 4762,
        loc_country: "Switzerland",
        loc_decimal_latitude: 49.27606815,
        loc_decimal_longitude: 11.408043484
      })

      update_record_fixtures!(Enum.at(records, 3), %{
        tax_taxon_id: 4762,
        loc_country: "Switzerland",
        loc_decimal_latitude: 47.27606815,
        loc_decimal_longitude: 9.408043484
      })

      {:ok, publication} = Collection.publish(publication, tenant: publication.collection)

      %{body: body} = Req.get!(publication.attachment.url)

      # validating if the core file is correctly created
      {core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert core_file_name != nil
      assert core_file_content != nil

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(core_file_content)

      assert_lists_equal(
        data_frame.names,
        DwcaFile.file_header_fields(:core),
        fn a, b -> a == b end
      )

      assert DataFrame.n_rows(data_frame) == 5

      rows = DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(
          rows,
          &Map.take(&1, [
            "decimalLongitude",
            "decimalLatitude"
          ])
        )

      expected = [
        %{
          "decimalLatitude" => 48.27606815,
          "decimalLongitude" => 10.408043484
        },
        %{
          "decimalLatitude" => 49.28,
          "decimalLongitude" => 11.41
        },
        %{
          "decimalLatitude" => 47.27606815,
          "decimalLongitude" => 9.408043484
        },
        %{
          "decimalLatitude" => 47.28,
          "decimalLongitude" => 9.41
        },
        %{
          "decimalLatitude" => nil,
          "decimalLongitude" => nil
        }
      ]

      assert_lists_equal(expected, transformed_attributes)
    end

    @tag capture_log: true
    test "publish/1 fails at register collection", %{
      publication_1: publication_1
    } do
      {:error, %Invalid{errors: errors}} =
        Collection.publish(publication_1, tenant: publication_1.collection)

      assert Enum.any?(errors, fn error ->
               String.contains?(error.message, "Error during collection registering")
             end)
    end

    @tag capture_log: true
    test "publish/1 fails at create endpoint", %{
      publication_2: publication_2
    } do
      {:error, %Invalid{errors: errors}} =
        Collection.publish(publication_2, tenant: publication_2.collection)

      assert Enum.any?(errors, fn error ->
               String.contains?(error.message, "Error during endpoint creation")
             end)
    end

    @tag capture_log: true
    test "publish/1 fails at get endpoints", %{
      publication_3: publication_3
    } do
      {:error, %Invalid{errors: errors}} =
        Collection.publish(publication_3, tenant: publication_3.collection)

      assert Enum.any?(errors, fn error ->
               String.contains?(error.message, "Error fetching existing endpoints")
             end)
    end

    @tag capture_log: true
    test "publish/1 fails at delete endpoint", %{
      publication_4: publication_4
    } do
      {:error, %Invalid{errors: errors}} =
        Collection.publish(publication_4, tenant: publication_4.collection)

      assert Enum.any?(errors, fn error ->
               String.contains?(error.message, "Error deleting endpoint")
             end)
    end

    test "run/1", %{
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, publication} = Publication.run(publication)

        assert publication.state == :done
      end)
    end

    @tag capture_log: true
    test "run/1 correctly sets states when failing at publish/register_at_gbif step", %{
      publication_1: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:error, %Invalid{}} = Publication.run(publication)

        collection = Collection.get_by_id!(publication.collection_id)
        publication = Publication.get_by_id!(publication.id, tenant: collection)

        query =
          Record
          |> AshPagify.query_for_filters_map(publication.records_query)
          |> Ash.Query.set_tenant(collection)

        records =
          query
          |> Ash.stream!()
          |> Stream.take(5)
          |> Enum.to_list()

        assert Enum.all?(records, &(&1.fast_track_status == :publication_failed))

        assert publication.state == :failed
        assert collection.state == :idle
      end)
    end

    test "enqueue/1", %{collection: collection, publication: publication} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, publication} = Publication.enqueue(publication)

        assert publication.state == :queued

        assert_enqueued(
          worker: Publisher,
          args: %{id: publication.id, collection_id: publication.collection_id}
        )

        collection = Collection.get_by_id!(collection.id)
        assert collection.state == :fast_track_publishing
      end)
    end

    test "enqueue/1 fails if collection is in state importing", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_importing!(collection)
        assert_not_enqueued(publication)
      end)
    end

    test "enqueue/1 fails if collection is in state exporting", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_exporting!(collection)
        assert_not_enqueued(publication)
      end)
    end

    test "enqueue/1 fails if collection is in state encoding", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_encoding!(collection)
        assert_not_enqueued(publication)
      end)
    end

    test "enqueue/1 fails if collection is in state approving", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_approving!(collection)
        assert_not_enqueued(publication)
      end)
    end

    test "enqueue/1 fails if collection is in state fast_track_publishing", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_fast_track_publishing!(collection)
        assert_not_enqueued(publication)
      end)
    end

    defp assert_not_enqueued(publication) do
      assert {:error, %Invalid{}} = Publication.enqueue(publication)
      publication = Publication.get_by_id!(publication.id, tenant: publication.collection)
      assert publication.state == :pending
      refute_enqueued(worker: Publisher, args: %{id: publication.id})
    end
  end
end
