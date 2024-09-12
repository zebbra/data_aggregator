defmodule DataAggregator.Records.Publication.Workers.PublisherTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.Workers.Publisher

  require Ash.Query

  describe "DataAggregator.Records.Publication.Workers.Publisher.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      records = [
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        tax_kingdom: %{is_nil: false}
      }

      publication =
        Publication.create!(%{
          name: "publication-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
          channel: :fast_track,
          collection: collection,
          records_query: query
        })

      [publication: publication, query: query, records: records]
    end

    test "publication :fast_track success", %{publication: publication} do
      perform_job(Publisher, %{id: publication.id})

      publication = Publication.get_by_id!(publication.id)

      assert publication.state == :done
      assert publication.channel == :fast_track
      assert publication.published_count == 5
    end

    test "publication :approval success", %{publication: publication} do
      perform_job(Publisher, %{id: publication.id})

      publication = Publication.get_by_id!(publication.id)
      publication = Publication.update!(publication, %{channel: :approval})

      assert publication.state == :done
      assert publication.channel == :approval
      assert publication.published_count == 5
    end
  end
end
