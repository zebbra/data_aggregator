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
      stub_with(Gbif.RestAPI, RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      collection_append =
        collection_fixture(%{
          name: "Collection append test",
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 10.0,
          loc_decimal_longitude: 10.0,
          loc_coordinate_uncertainty_in_meters: 5000.0
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 166.4713889,
          loc_decimal_longitude: 640_000.0,
          loc_coordinate_uncertainty_in_meters: 400.004
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 47.27606815,
          loc_decimal_longitude: 9.408043484,
          loc_coordinate_uncertainty_in_meters: 3.03
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
      encoded_record_append_1 |> Ash.update!(%{tax_taxon_id: "4762"}) |> Map.get(:tax_taxon_id)
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
            name: "Publication 2",
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      publication_append_1 =
        Publication.create!(
          %{
            name: "Publication append test",
            records_query: query_append_1,
            collection: collection_append
          },
          tenant: collection_append
        )

      publication_append_2 =
        Publication.create!(
          %{
            name: "Publication append test",
            records_query: query_append_2,
            collection: collection_append
          },
          tenant: collection_append
        )

      publication_append_3 =
        Publication.create!(
          %{
            name: "Publication append test",
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

      assert core_file_name
      assert core_file_content

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
            "decimalLatitude",
            "coordinateUncertaintyInMeters"
          ])
        )

      transformed_expected = [
        %{
          "decimalLatitude" => 10.0,
          "decimalLongitude" => 10.0,
          "coordinateUncertaintyInMeters" => 5000.0
        },
        %{
          "decimalLatitude" => 166.4713889,
          "decimalLongitude" => 640_000.0,
          "coordinateUncertaintyInMeters" => 400.004
        },
        %{
          "decimalLatitude" => 47.27606815,
          "decimalLongitude" => 9.408043484,
          "coordinateUncertaintyInMeters" => 3.03
        },
        %{
          "decimalLatitude" => nil,
          "decimalLongitude" => nil,
          "coordinateUncertaintyInMeters" => nil
        },
        %{
          "decimalLatitude" => nil,
          "decimalLongitude" => nil,
          "coordinateUncertaintyInMeters" => nil
        }
      ]

      assert_lists_equal(transformed_expected, transformed_attributes)

      collection_attributes =
        Enum.map(
          rows,
          &Map.take(&1, [
            "collectionID",
            "collectionCode",
            "collectionCode",
            "institutionCode",
            "institutionID",
            "datasetID"
          ])
        )

      collection_expected = [
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33"
        },
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33"
        },
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33"
        },
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33"
        },
        %{
          "collectionID" => "322ce107-3156-4420-8a2b-7f17efeaa472",
          "collectionCode" => "Z",
          "datasetID" => "1234-1234-1234-1234",
          "institutionCode" => "Z",
          "institutionID" => "5b487a79-76ef-4615-93d9-f4ea25a40c33"
        }
      ]

      assert_lists_equal(collection_expected, collection_attributes)
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

      # default publication is on layer 'validation' so the value saved in published_records are encoded_record values
      assert published_records |> List.first() |> Map.get(:tax_taxon_id) == "4762"
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
      assert published_records |> List.first() |> Map.get(:tax_taxon_id) == "4762"
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

    test "publish/1 succesful with publication rules (coordinate obfuscation)", %{
      publication: publication,
      records: records
    } do
      expect_correct_swiss_species_api_call(3)

      update_record_fixtures!(Enum.at(records, 0), %{
        tax_taxon_id: "4762",
        loc_decimal_latitude: 48.27606815,
        loc_decimal_longitude: 10.408043484
      })

      update_record_fixtures!(Enum.at(records, 1), %{
        tax_taxon_id: "4762",
        loc_country: "Switzerland",
        loc_decimal_latitude: 47.585812203,
        loc_decimal_longitude: 9.166888228
      })

      update_record_fixtures!(Enum.at(records, 2), %{
        tax_taxon_id: "4762",
        loc_country: "Switzerland",
        loc_decimal_latitude: 47.585812401,
        loc_decimal_longitude: 9.166874938
      })

      update_record_fixtures!(Enum.at(records, 3), %{
        tax_taxon_id: "4762",
        loc_country: "Switzerland",
        loc_decimal_latitude: 47.27606815,
        loc_decimal_longitude: 9.408043484
      })

      {:ok, publication} = Collection.publish(publication, tenant: publication.collection)

      %{body: body} = Req.get!(publication.attachment.url)

      # validating if the core file is correctly created
      {core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert core_file_name
      assert core_file_content

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
            "decimalLatitude",
            "coordinateUncertaintyInMeters"
          ])
        )

      expected = [
        %{
          "decimalLatitude" => 48.27606815,
          "decimalLongitude" => 10.408043484,
          "coordinateUncertaintyInMeters" => 5000.0
        },
        %{
          "decimalLatitude" => 47.5898085,
          "decimalLongitude" => 9.2002562,
          "coordinateUncertaintyInMeters" => 3535.0
        },
        %{
          "decimalLatitude" => 47.5907987,
          "decimalLongitude" => 9.1338001,
          "coordinateUncertaintyInMeters" => 3535.0
        },
        %{
          "decimalLatitude" => 47.2719116,
          "decimalLongitude" => 9.3880537,
          "coordinateUncertaintyInMeters" => 3535.0
        },
        %{
          "decimalLatitude" => nil,
          "decimalLongitude" => nil,
          "coordinateUncertaintyInMeters" => nil
        }
      ]

      assert_lists_equal(expected, transformed_attributes)
    end

    @tag capture_log: true
    test "publish/1 fails at get dataset", %{
      publication: publication
    } do
      stub(Gbif.RestAPI, :get_dataset, fn _collection_name ->
        {:error, %{status: 400, body: "error getting dataset"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.publish(publication, tenant: publication.collection)
        end)

      assert logs =~ "Error publishing records:"
      assert logs =~ "Error registering dataset at GBIF"
      assert logs =~ "error getting dataset"
    end

    @tag capture_log: true
    test "publish/1 fails at register collection", %{
      publication: publication
    } do
      stub(Gbif.RestAPI, :register_dataset, fn _collection_name ->
        {:error, %{status: 400, body: "error registering collection"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.publish(publication, tenant: publication.collection)
        end)

      assert logs =~ "Error publishing records:"
      assert logs =~ "Error during collection registering"
      assert logs =~ "error registering collection"
    end

    @tag capture_log: true
    test "publish/1 fails at create endpoint", %{
      publication: publication
    } do
      stub(Gbif.RestAPI, :create_endpoint, fn _file_url, _registration ->
        {:error, %{status: 400, body: "could not create endpoint"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.publish(publication, tenant: publication.collection)
        end)

      assert logs =~ "Error publishing records:"
      assert logs =~ "Error during endpoint creation"
      assert logs =~ "could not create endpoint"
    end

    @tag capture_log: true
    test "publish/1 fails at get endpoints", %{
      publication: publication
    } do
      stub(Gbif.RestAPI, :get_endpoints, fn _dataset_key ->
        {:error, %{status: 400, body: "error getting endpoints"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.publish(publication, tenant: publication.collection)
        end)

      assert logs =~ "Error publishing records:"
      assert logs =~ "Error fetching existing endpoints for dataset"
      assert logs =~ "error getting endpoints"
    end

    @tag capture_log: true
    test "publish/1 fails at delete endpoint", %{
      publication: publication
    } do
      stub(Gbif.RestAPI, :delete_endpoint, fn _dataset_key, _endpoint_key ->
        {:error, %{status: 400, body: "error response deleting endpoint"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.publish(publication, tenant: publication.collection)
        end)

      assert logs =~ "Error publishing records:"
      assert logs =~ "Error deleting endpoint"
      assert logs =~ "error response deleting endpoint"
    end

    test "run/1", %{
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, publication} = Publication.run(publication)

        publication = Ash.load!(publication, [:publication_progress])

        assert publication.state == :done
        assert publication.publication_progress == 1.0
      end)
    end

    @tag capture_log: true
    test "run/1 correctly sets states when failing at publish/register_at_gbif step", %{
      publication: publication
    } do
      stub(Gbif.RestAPI, :register_dataset, fn _collection_name ->
        {:error, %{status: 400, body: "error registering collection"}}
      end)

      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:error, _error} = Publication.run(publication)

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

        assert Enum.all?(records, &(&1.publication_status == :publication_failed))

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
        assert collection.state == :publishing
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

    test "enqueue/1 fails if collection is in state validating", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_validating!(collection)
        assert_not_enqueued(publication)
      end)
    end

    test "enqueue/1 fails if collection is in state publishing", %{
      collection: collection,
      publication: publication
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        Collection.set_publishing!(collection)
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
