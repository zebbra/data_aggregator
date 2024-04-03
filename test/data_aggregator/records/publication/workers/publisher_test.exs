defmodule DataAggregator.Records.Publication.Workers.PublisherTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic.DSL

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  require Ash.Query

  describe "DataAggregator.Records.Publication.Workers.Publisher.perform/1" do
    setup do
      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      records = [
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "My Kingdom"
        })
      ]

      query =
        Record
        |> Ash.Query.load(collection: [:id])
        |> Ash.Query.filter(
          collection.id == collection.id and
            not is_nil(tax_kingdom)
        )

      publication =
        Publication.create!(%{
          name: "publication-#{collection.name}-#{Ecto.UUID.generate()}",
          channel: :fast_track,
          collection: collection,
          mapping: nil,
          records_query: query
        })

      [publication: publication, query: query, records: records]
    end

    test "publication success", %{publication: publication} do
      perform_job(Publication.Workers.Publisher, %{id: publication.id})

      publication = Publication.get_by_id!(publication.id)

      assert publication.state == :done
      assert publication.published_count == 10
    end
  end
end
