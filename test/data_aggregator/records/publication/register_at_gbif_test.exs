defmodule DataAggregator.RegisterAtGbifTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  require Ash.Query

  describe "Publish to Gbif (fast_track) tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection =
        collection_fixture(%{
          name: "Collection NumberOne",
          grscicoll_reference: "813a1cea-f762-11e1-a439-00145eb45e9a"
        })

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          fast_track_status: :in_publication
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          fast_track_status: :in_publication
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          fast_track_status: :in_publication
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          fast_track_status: :in_publication
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom",
          fast_track_status: :in_publication
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
        Publication.create!(
          %{
            name: "Publication Fast Track",
            channel: :fast_track,
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      {:ok, publication} = Collection.publish(publication, tenant: collection)
      publication = Ash.load!(publication, [:attachment], tenant: collection)

      [
        collection: collection,
        records: records,
        publication: publication
      ]
    end

    test "register_at_gbif/2 success", %{
      collection: collection,
      publication: publication
    } do
      {:ok, collection} =
        Collection.register_at_gbif(collection, publication.attachment.url)

      assert collection.gbif_dataset_key === "1234-1234-1234-1234"
    end

    test "register_at_gbif/2 registration failed", %{
      collection: collection,
      publication: publication
    } do
      stub(Gbif.RestAPI, :register_dataset, fn _collection_name ->
        {:ok, %{status: 400, body: "Failed due to bla"}}
      end)

      {{:error, error}, logs} =
        with_log(fn -> Collection.register_at_gbif(collection, publication.attachment.url) end)

      assert collection.gbif_dataset_key === nil
      assert %Invalid{} = error

      assert logs =~ "Failed due to bla"
    end

    test "register_at_gbif/2 endpoint creation failed", %{
      collection: collection,
      publication: publication
    } do
      stub(Gbif.RestAPI, :create_endpoint, fn _file_url, _registration ->
        {:ok, %{status: 418, body: "I'm a teapot"}}
      end)

      {{:error, error}, logs} =
        with_log(fn -> Collection.register_at_gbif(collection, publication.attachment.url) end)

      assert collection.gbif_dataset_key === nil
      assert %Invalid{} = error

      assert logs =~ "I'm a teapot"
    end

    test "check_if_fast_track_published/2 success", %{collection: collection} do
      record_to_check = get_record_to_check(collection)

      {:ok, record} = Record.check_if_fast_track_pubished(record_to_check)

      assert record.fast_track_status === :published
    end

    test "check_if_fast_track_published/2 not published yet", %{collection: collection} do
      stub(Gbif.RestAPI, :search_for_occurrences, fn _catalog_number, _dataset_key ->
        {:ok, %{status: 200, body: %{"results" => []}}}
      end)

      record_to_check = get_record_to_check(collection)

      {:ok, record} = Record.check_if_fast_track_pubished(record_to_check)

      assert record.fast_track_status === :in_publication
    end

    test "check_if_fast_track_published/2 failed with non http 200", %{collection: collection} do
      stub(Gbif.RestAPI, :search_for_occurrences, fn _catalog_number, _dataset_key ->
        {:ok, %{status: 500, body: %{}}}
      end)

      record_to_check = get_record_to_check(collection)

      {{:error, error}, logs} =
        with_log(fn -> Record.check_if_fast_track_pubished(record_to_check) end)

      record = Record.get_by_id!(record_to_check.id, tenant: collection)

      assert record.fast_track_status === :in_publication
      assert %Invalid{} = error

      assert logs =~
               "Error while checking if record is published: \"No valid response (status 500) from GBIF API while searching for occurrences"
    end

    test "check_if_fast_track_published/2 failed with multiple occurrences found", %{
      collection: collection
    } do
      stub(Gbif.RestAPI, :search_for_occurrences, fn _catalog_number, _dataset_key ->
        {:ok, %{status: 200, body: %{"results" => [%{"key" => "1"}, %{"key" => "2"}]}}}
      end)

      record_to_check = get_record_to_check(collection)

      {{:error, error}, logs} =
        with_log(fn -> Record.check_if_fast_track_pubished(record_to_check) end)

      record = Record.get_by_id!(record_to_check.id, tenant: collection)

      assert record.fast_track_status === :in_publication
      assert %Invalid{} = error

      assert logs =~
               "More than one occurrence found on GBIF"
    end
  end

  defp get_record_to_check(collection) do
    record_fixture(%{
      collection: collection,
      mte_catalog_number: "MZL-INVERT-182861",
      fast_track_status: :in_publication
    })
  end
end
