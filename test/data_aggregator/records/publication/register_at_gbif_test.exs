defmodule DataAggregator.RegisterAtGbifTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  require Ash.Query

  describe "Publish to Gbif (fast_track) tests" do
    setup do
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
        Records.load!(record1, [:encoded_record]),
        Records.load!(record2, [:encoded_record]),
        Records.load!(record3, [:encoded_record]),
        Records.load!(record4, [:encoded_record]),
        Records.load!(record5, [:encoded_record])
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      publication =
        Publication.create!(%{
          name: "Publication Fast Track",
          channel: :fast_track,
          records_query: query,
          collection: collection
        })

      {:ok, publication} = Collection.publish(publication)
      publication = Records.load!(publication, [:attachment])

      [collection: collection, records: records, publication: publication]
    end

    test "register_at_gbif/2 success", %{
      collection: collection,
      records: _records,
      publication: publication
    } do
      # note for anyone facing the issue of having his/her stub/expect not called:
      # make sure that the function you are stubbing/expecting is called NOT within the
      # same module the function is declared!
      # https://github.com/edgurgel/mimic/issues/27
      stub(Gbif.RestApi, :register_dataset, fn _collection_name ->
        {:ok, %{status: 201, body: "1234-1234-1234-1234"}}
      end)

      stub(Gbif.RestApi, :create_endpoint, fn _file_url, _registration ->
        {:ok, %{status: 201, body: "1234"}}
      end)

      {:ok, collection} =
        Collection.register_at_gbif(collection, publication.attachment.url)

      assert collection.gbif_dataset_key === "1234-1234-1234-1234"
    end

    test "register_at_gbif/2 registration failed", %{
      collection: collection,
      records: _records,
      publication: publication
    } do
      stub(Gbif.RestApi, :register_dataset, fn _collection_name ->
        {:ok, %{status: 400, body: "Failed due to bla"}}
      end)

      {{:error, error}, logs} =
        with_log(fn -> Collection.register_at_gbif(collection, publication.attachment.url) end)

      assert collection.gbif_dataset_key === nil
      assert %Ash.Error.Invalid{} = error

      assert logs =~ "Failed due to bla"
    end

    test "register_at_gbif/2 endpoint creation failed", %{
      collection: collection,
      records: _records,
      publication: publication
    } do
      stub(Gbif.RestApi, :register_dataset, fn _collection_name ->
        {:ok, %{status: 201, body: "1234-1234-1234-1234"}}
      end)

      stub(Gbif.RestApi, :create_endpoint, fn _file_url, _registration ->
        {:ok, %{status: 418, body: "I'm a teapot"}}
      end)

      {{:error, error}, logs} =
        with_log(fn -> Collection.register_at_gbif(collection, publication.attachment.url) end)

      assert collection.gbif_dataset_key === nil
      assert %Ash.Error.Invalid{} = error

      assert logs =~ "I'm a teapot"
    end
  end
end
