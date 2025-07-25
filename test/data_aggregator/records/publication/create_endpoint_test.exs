defmodule DataAggregator.CreateEndpointTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  describe "Creating endpoints at GBIF tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection =
        collection_fixture(%{
          name: "Collection NumberOne",
          grscicoll_reference: "813a1cea-f762-11e1-a439-00145eb45e9a",
          gbif_dataset_key: "some-dataset-key"
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

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})

      records = [
        Ash.load!(record1, [:encoded_record]),
        Ash.load!(record2, [:encoded_record])
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
        publication: publication,
        records: records
      ]
    end

    test "create_endpoint/2 success", %{
      collection: collection
    } do
      {:ok, _dataset_key} = Collection.create_endpoint(collection, "some_file_url")
    end

    test "create_endpoint/2 endpoint creation failed", %{
      collection: collection
    } do
      stub(Gbif.RestAPI, :create_endpoint, fn _file_url, _registration ->
        {:ok, %{status: 418, body: "I'm a teapot"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.create_endpoint(collection, "some_file_url")
        end)

      assert logs =~ "I'm a teapot"
      assert logs =~ "No valid response"
    end

    test "create_endpoint/2 delete old endpoints failed", %{
      collection: collection
    } do
      stub(Gbif.RestAPI, :delete_endpoint, fn _file_url, _registration ->
        {:error, %{status: 418, body: "I'm a teapot"}}
      end)

      {{:error, _error}, logs} =
        with_log(fn ->
          Collection.create_endpoint(collection, "some_file_url")
        end)

      assert logs =~ "I'm a teapot"
      assert logs =~ "Error deleting endpoint"
    end
  end
end
