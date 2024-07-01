defmodule DataAggregator.PublicationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias Explorer.DataFrame

  require Ash.Query

  describe "publication tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
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

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})

      records = [
        Ash.load!(record1, [:encoded_record]),
        Ash.load!(record2, [:encoded_record]),
        Ash.load!(record3, [:encoded_record]),
        Ash.load!(record4, [:encoded_record]),
        Ash.load!(record5, [:encoded_record])
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      publication =
        Publication.create!(%{
          name: "Publication Fast Track ",
          channel: :fast_track,
          records_query: query,
          collection: collection
        })

      [collection: collection, records: records, publication: publication]
    end

    test "publish/1", %{collection: _collection, records: _records, publication: publication} do
      {:ok, publication} = Collection.publish(publication)

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
    end

    test "enqueue/1", %{collection: collection, publication: publication} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, publication} = Publication.enqueue(publication)

        assert publication.state == :queued
        assert_enqueued(worker: Publication.Workers.Publisher, args: %{id: publication.id})

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
      assert {:error, %Ash.Error.Invalid{}} = Publication.enqueue(publication)
      publication = Publication.get_by_id!(publication.id)
      assert publication.state == :pending
      refute_enqueued(worker: Publication.Workers.Publisher, args: %{id: publication.id})
    end
  end
end
