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

  require Ash.Query

  describe "Registering Collection at GBIF tests" do
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
          publication_status: :in_publication
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          publication_status: :in_publication
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          publication_status: :in_publication
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          publication_status: :in_publication
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom",
          publication_status: :in_publication
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
            name: "Publication",
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      [
        collection: collection,
        records: records,
        publication: publication
      ]
    end

    test "register_at_gbif/2 success", %{
      collection: collection
    } do
      {:ok, collection} =
        Collection.register_at_gbif(collection, nil)

      assert collection.gbif_dataset_key === "1234-1234-1234-1234"
    end

    test "register_at_gbif/2 success using existing dataset key", %{
      collection: collection
    } do
      {:ok, collection} =
        Collection.register_at_gbif(collection, "1111-1111-1111-1111")

      assert collection.gbif_dataset_key === "1111-1111-1111-1111"
    end

    test "register_at_gbif/2 registration failed", %{
      collection: collection
    } do
      stub(Gbif.RestAPI, :register_dataset, fn _collection_name ->
        {:ok, %{status: 400, body: "Failed due to bla"}}
      end)

      {{:error, error}, logs} =
        with_log(fn ->
          Collection.register_at_gbif(collection, nil)
        end)

      assert collection.gbif_dataset_key === nil
      assert %Invalid{} = error

      assert logs =~ "Failed due to bla"
    end
  end
end
